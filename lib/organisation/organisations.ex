#  MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule Organisation.Organisations do
  alias MoodleNet.{Activities, Actors, Common, Feeds, Follows, Repo}
  alias MoodleNet.GraphQL.{Fields, Page}
  alias MoodleNet.Common.Contexts
  alias Organisation
  alias Organisation.Queries
  alias MoodleNet.Feeds.FeedActivities
  alias MoodleNet.Users.User
  alias MoodleNet.Workers.APPublishWorker

  def cursor(:followers), do: &[&1.follower_count, &1.id]
  def test_cursor(:followers), do: &[&1["followerCount"], &1["id"]]

  @doc """
  Retrieves a single organisation by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for organisations (inc. tests)
  """
  def one(filters), do: Repo.single(Queries.query(Organisation, filters))

  @doc """
  Retrieves a list of organisations by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for organisations (inc. tests)
  """
  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Organisation, filters))}

  def fields(group_fn, filters \\ [])
  when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of organisations according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  def page(cursor_fn, %{}=page_opts, base_filters, data_filters, count_filters) do
    base_q = Queries.query(Organisation, base_filters)
    data_q = Queries.filter(base_q, data_filters)
    count_q = Queries.filter(base_q, count_filters)
    with {:ok, [data, counts]} <- Repo.transact_many(all: data_q, count: count_q) do
      {:ok, Page.new(data, counts, cursor_fn, page_opts)}
    end
  end

  @doc """
  Retrieves an Pages of organisations according to various filters

  Used by:
  * GraphQL resolver bulk resolution
  """
  def pages(cursor_fn, group_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  def pages(cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters) do
    Contexts.pages Queries, Organisation,
      cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters
  end

  ## mutations
  @spec create(User.t(), attrs :: map) :: {:ok, Organisation.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->
      with {:ok, actor} <- Actors.create(attrs),
           {:ok, org_attrs} <- create_boxes(actor, attrs),
           {:ok, org} <- insert_organisation(creator, actor, org_attrs),
           {:ok, index} <- Search.Indexing.maybe_index_object(org), # add to search index
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <- Activities.create(creator, org, act_attrs),
           :ok <- publish(creator, org, activity, :created),
           {:ok, _follow} <- Follows.create(creator, org, %{is_local: true}) do
        {:ok, org}
      end
    end)
  end

  @spec create(User.t(), context :: any, attrs :: map) :: {:ok, Organisation.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, context, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->
      with {:ok, actor} <- Actors.create(attrs),
           {:ok, org_attrs} <- create_boxes(actor, attrs),
           {:ok, org} <- insert_organisation(creator, context, actor, org_attrs),
           {:ok, index} <- Search.Indexing.maybe_index_object(org), # add to search index
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <- Activities.create(creator, org, act_attrs),
           :ok <- publish(creator, context, org, activity, :created),
           {:ok, _follow} <- Follows.create(creator, org, %{is_local: true}) do
        {:ok, org}
      end
    end)
  end

  defp create_boxes(%{peer_id: nil}, attrs), do: create_local_boxes(attrs)
  defp create_boxes(%{peer_id: _}, attrs), do: create_remote_boxes(attrs)

  defp create_local_boxes(attrs) do
    with {:ok, inbox} <- Feeds.create(),
         {:ok, outbox} <- Feeds.create() do
      extra = %{inbox_id: inbox.id, outbox_id: outbox.id}
      {:ok, Map.merge(attrs, extra)}
    end
  end

  defp create_remote_boxes(attrs) do
    with {:ok, outbox} <- Feeds.create() do
      {:ok, Map.put(attrs, :outbox_id, outbox.id)}
    end
  end

  defp insert_organisation(creator, actor, attrs) do
    cs = Organisation.create_changeset(creator, actor, attrs)
    with {:ok, org} <- Repo.insert(cs), do: {:ok, %{ org | actor: actor }}
  end

  defp insert_organisation(creator, context, actor, attrs) do
    cs = Organisation.create_changeset(creator, actor, context, attrs)
    with {:ok, org} <- Repo.insert(cs), do: {:ok, %{ org | actor: actor, context: context }}
  end

  defp publish(creator, organisation, activity, :created) do
    feeds = [
      creator.outbox_id,
      organisation.outbox_id, Feeds.instance_outbox_id(),
    ]
    with :ok <- FeedActivities.publish(activity, feeds),
         {:ok, _} <- ap_publish("create", organisation.id, creator.id, organisation.actor.peer_id),
      do: :ok
  end

  defp publish(creator, community, organisation, activity, :created) do
    feeds = [
      community.outbox_id, creator.outbox_id,
      organisation.outbox_id, Feeds.instance_outbox_id(),
    ]
    with :ok <- FeedActivities.publish(activity, feeds),
         {:ok, _} <- ap_publish("create", organisation.id, creator.id, organisation.actor.peer_id),
      do: :ok
  end

  defp publish(organisation, :updated) do
    # TODO: wrong if edited by admin
    with {:ok, _} <- ap_publish("update", organisation.id, organisation.creator_id, organisation.actor.peer_id),
      do: :ok
  end
  defp publish(organisation, :deleted) do
    # TODO: wrong if edited by admin
    with {:ok, _} <- ap_publish("delete", organisation.id, organisation.creator_id, organisation.actor.peer_id),
      do: :ok
  end

  defp ap_publish(verb, context_id, user_id, nil) do
    APPublishWorker.enqueue(verb, %{
      "context_id" => context_id,
      "user_id" => user_id,
    })
  end
  defp ap_publish(_, _, _), do: :ok

  # TODO: take the user who is performing the update
  @spec update(User.t(), Organisation.t(), attrs :: map) :: {:ok, Organisation.t()} | {:error, Changeset.t()}
  def update(%User{} = user, %Organisation{} = organisation, attrs) do
    Repo.transact_with(fn ->
      with {:ok, organisation} <- Repo.update(Organisation.update_changeset(organisation, attrs)),
           {:ok, actor} <- Actors.update(user, organisation.actor, attrs),
           :ok <- publish(organisation, :updated) do
        {:ok, %{ organisation | actor: actor }}
      end
    end)
  end

  def soft_delete(%Organisation{} = organisation) do
    Repo.transact_with(fn ->
      with {:ok, organisation} <- Common.soft_delete(organisation),
           :ok <- publish(organisation, :deleted) do
        {:ok, organisation}
      end
    end)
  end

end
