# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observation.Process.Processes do
  alias CommonsPub.{Activities, Common, Feeds, Repo}
  alias CommonsPub.GraphQL.{Fields, Page}
  alias CommonsPub.Common.Contexts
  alias CommonsPub.Feeds.FeedActivities
  alias CommonsPub.Users.User
  # alias CommonsPub.Meta.Pointers

  # alias Geolocation.Geolocations
  # alias Measurement.Measure
  alias ValueFlows.Observation.Process
  alias ValueFlows.Observation.Process.Queries
  alias ValueFlows.Observation.EconomicEvent.EconomicEvents

  def cursor(), do: &[&1.id]
  def test_cursor(), do: &[&1["id"]]

  @doc """
  Retrieves a single one by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for this (inc. tests)
  """
  def one(filters), do: Repo.single(Queries.query(Process, filters))

  @doc """
  Retrieves a list of them by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for this (inc. tests)
  """
  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Process, filters))}

  def fields(group_fn, filters \\ [])
      when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of processes according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])

  def page(cursor_fn, %{} = page_opts, base_filters, data_filters, count_filters) do
    base_q = Queries.query(Process, base_filters)
    data_q = Queries.filter(base_q, data_filters)
    count_q = Queries.filter(base_q, count_filters)

    with {:ok, [data, counts]} <- Repo.transact_many(all: data_q, count: count_q) do
      {:ok, Page.new(data, counts, cursor_fn, page_opts)}
    end
  end

  @doc """
  Retrieves an Pages of processes according to various filters

  Used by:
  * GraphQL resolver bulk resolution
  """
  def pages(
        cursor_fn,
        group_fn,
        page_opts,
        base_filters \\ [],
        data_filters \\ [],
        count_filters \\ []
      )

  def pages(cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters) do
    Contexts.pages(
      Queries,
      Process,
      cursor_fn,
      group_fn,
      page_opts,
      base_filters,
      data_filters,
      count_filters
    )
  end

  def track(process), do: outputs(process)

  def trace(process), do: inputs(process)

  def inputs(%{id: id}, action_id \\ nil) when not is_nil(action_id) do
    EconomicEvents.many([:default, input_of_id: id, action_id: action_id])
  end

  def inputs(%{id: id}, _) do
    EconomicEvents.many([:default, input_of_id: id])
  end

  def inputs(_, _) do
    {:ok, nil}
  end

  def outputs(%{id: id}, action_id \\ nil) when not is_nil(action_id) do
    EconomicEvents.many([:default, output_of_id: id, action_id: action_id])
  end

  def outputs(%{id: id}, _) do
    EconomicEvents.many([:default, output_of_id: id])
  end

  def outputs(_, _) do
    {:ok, nil}
  end

  ## mutations

  def create(%User{} = creator, %{id: _id} = context, attrs)
      when is_map(attrs) do
    do_create(creator, attrs, fn ->
      Process.create_changeset(creator, context, attrs)
    end)
  end

  # @spec create(User.t(), attrs :: map) :: {:ok, Process.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, attrs) when is_map(attrs) do
    do_create(creator, attrs, fn ->
      Process.create_changeset(creator, attrs)
    end)
  end

  def do_create(creator, attrs, changeset_fn) do
    Repo.transact_with(fn ->
      cs = changeset_fn.()

      with {:ok, process} <- Repo.insert(cs),
           {:ok, process} <- ValueFlows.Util.try_tag_thing(creator, process, attrs),
           act_attrs = %{verb: "created", is_local: true},
           # FIXME
           {:ok, activity} <- Activities.create(creator, process, act_attrs),
           :ok <- publish(creator, process, activity, :created) do
        process = %{process | creator: creator}
        index(process)
        {:ok, process}
      end
    end)
  end

  defp publish(creator, process, activity, :created) do
    feeds = [
      CommonsPub.Feeds.outbox_id(creator),
      Feeds.instance_outbox_id()
    ]

    with :ok <- FeedActivities.publish(activity, feeds) do
      ap_publish("create", process.id, creator.id)
    end
  end

  defp publish(creator, context, process, activity, :created) do
    feeds = [
      context.outbox_id,
      CommonsPub.Feeds.outbox_id(creator),
      Feeds.instance_outbox_id()
    ]

    with :ok <- FeedActivities.publish(activity, feeds) do
      ap_publish("create", process.id, creator.id)
    end
  end

  defp publish(process, :updated) do
    # TODO: wrong if edited by admin
    ap_publish("update", process.id, process.creator_id)
  end

  defp publish(process, :deleted) do
    # TODO: wrong if edited by admin
    ap_publish("delete", process.id, process.creator_id)
  end

  # FIXME
  defp ap_publish(verb, context_id, user_id) do
    CommonsPub.Workers.APPublishWorker.enqueue(verb, %{
      "context_id" => context_id,
      "user_id" => user_id
    })

    :ok
  end

  defp ap_publish(_, _, _), do: :ok

  # TODO: take the user who is performing the update
  # @spec update(%Process{}, attrs :: map) :: {:ok, Process.t()} | {:error, Changeset.t()}
  def update(%Process{} = process, attrs) do
    do_update(process, attrs, &Process.update_changeset(&1, attrs))
  end

  def do_update(process, attrs, changeset_fn) do
    Repo.transact_with(fn ->
      process =
        Repo.preload(process, [
          :based_on
        ])

      cs =
        process
        |> changeset_fn.()

      with {:ok, process} <- Repo.update(cs),
           {:ok, process} <- ValueFlows.Util.try_tag_thing(nil, process, attrs),
           :ok <- publish(process, :updated) do
        {:ok, process}
      end
    end)
  end

  def soft_delete(%Process{} = process) do
    Repo.transact_with(fn ->
      with {:ok, process} <- Common.soft_delete(process),
           :ok <- publish(process, :deleted) do
        {:ok, process}
      end
    end)
  end

  def indexing_object_format(obj) do
    # icon = CommonsPub.Uploads.remote_url_from_id(obj.icon_id)
    %{
      "index_type" => "Process",
      "id" => obj.id,
      # "canonicalUrl" => obj.canonical_url,
      # "icon" => icon,
      "name" => obj.name,
      "summary" => Map.get(obj, :note),
      "published_at" => obj.published_at,
      "creator" => CommonsPub.Search.Indexer.format_creator(obj)
      # "index_instance" => URI.parse(obj.canonical_url).host, # home instance of object
    }
  end

  defp index(obj) do
    object = indexing_object_format(obj)

    CommonsPub.Search.Indexer.maybe_index_object(object)

    :ok
  end
end
