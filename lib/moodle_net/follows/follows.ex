# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Follows do
  alias MoodleNet.{Activities, Common, GraphQL, Repo}
  alias MoodleNet.Batching.{Edges, EdgesPages, NodesPage}
  alias MoodleNet.Feeds.{FeedActivities, FeedSubscriptions}
  alias MoodleNet.Follows.{
    AlreadyFollowingError,
    Follow,
    NotFollowableError,
    Queries,
  }
  alias MoodleNet.Meta.{Pointer, Pointers}
  alias MoodleNet.Users.{LocalUser, User}
  alias Ecto.Changeset

  def one(filters), do: Repo.single(Queries.query(Follow, filters))

  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Follow, filters))}

  def nodes_page(cursor_fn, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  when is_function(cursor_fn, 1) do
    {data_q, count_q} = Queries.queries(Follow, base_filters, data_filters, count_filters)
    with {:ok, [data, count]} <- Repo.transact_many(all: data_q, count: count_q) do
      {:ok, NodesPage.new(data, count, cursor_fn)}
    end
  end

  def edges(group_fn, filters \\ [])
  when is_function(group_fn, 1) do
    {:ok, edges} = many(filters)
    {:ok, Edges.new(edges, group_fn)}
  end

  def edges_pages(group_fn, cursor_fn, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  when is_function(group_fn, 1) and is_function(cursor_fn, 1) do
    {data_q, count_q} = Queries.queries(Follow, base_filters, data_filters, count_filters)
    with {:ok, [data, count]} <- Repo.transact_many(all: data_q, all: count_q) do
      {:ok, EdgesPages.new(data, count, group_fn, cursor_fn)}
    end
  end

  @type create_opt :: {:publish, bool} | {:federate, bool}
  @type create_opts :: [create_opt]

  @spec create(User.t(), any, map) :: {:ok, Follow.t()} | {:error, Changeset.t()}
  @spec create(User.t(), any, map, create_opts) :: {:ok, Follow.t()} | {:error, Changeset.t()}

  def create(follower, followed, fields, opts \\ [])
  def create(%User{} = follower, %Pointer{}=followed, %{}=fields, opts) do
    create(follower, Pointers.follow!(followed), fields, opts)
  end
  def create(%User{} = follower, %{outbox_id: _}=followed, fields, opts) do
    if followed.__struct__ in valid_contexts() do
      Repo.transact_with(fn ->
        case one(creator_id: follower.id, context_id: followed.id) do
          {:ok, _} ->
            {:error, AlreadyFollowingError.new("user")}
  
          _ ->
            with {:ok, follow} <- insert(follower, followed, fields),
                 :ok <- subscribe(follower, followed, follow),
                 :ok <- publish(follower, followed, follow, :created, opts) do
              {:ok, %{follow | ctx: followed}}
            end
        end
      end)
    else
      GraphQL.not_permitted()
    end
  end

  defp insert(follower, followed, fields) do
    Repo.insert(Follow.create_changeset(follower, followed, fields))
  end

  defp publish(creator, followed, %Follow{} = follow, :created, opts) do
    if Keyword.get(opts, :publish, true) do
      attrs = %{verb: "created", is_local: follow.is_local}
      with {:ok, activity} <- Activities.create(creator, follow, attrs) do
        FeedActivities.publish(activity, [creator.outbox_id, followed.outbox_id])
      end
    end
  end

  defp federate(follow, opts \\ [])
  defp federate(%Follow{is_local: true} = follow, opts) do
    if Keyword.get(opts, :federate, true) do
      MoodleNet.FeedPublisher.publish(%{
        "context_id" => follow.context_id,
        "user_id" => follow.creator_id,
      })
    else
      :ok
    end
  end
  defp federate(_, _), do: :ok

  @spec update(Follow.t(), map) :: {:ok, Follow.t()} | {:error, Changeset.t()}
  def update(%Follow{} = follow, fields) do
    Repo.transact_with(fn ->
      follow
      |> Follow.update_changeset(fields)
      |> Repo.update()
    end)
  end

  @spec undo(Follow.t()) :: {:ok, Follow.t()} | {:error, Changeset.t()}
  def undo(%Follow{is_local: false}), do: {:error, :not_local}
  def undo(%Follow{is_local: true} = follow) do
    Repo.transact_with(fn ->
      with {:ok, _} <- unsubscribe(follow),
           {:ok, follow} <- Common.soft_delete(follow),
           :ok <- federate(follow) do
        {:ok, follow}
      end
    end)
  end

  # we only maintain subscriptions for local users
  defp subscribe(%User{local_user: %LocalUser{}}=follower, %{outbox_id: outbox_id}, %Follow{muted_at: nil})
  when is_binary(outbox_id) do
    case FeedSubscriptions.one(subscriber_id: follower.id, feed_id: outbox_id) do
      {:ok, _} -> :ok
      _ ->
        with {:ok, _} <- FeedSubscriptions.create(follower, outbox_id, %{is_active: true}), do: :ok
    end
  end
  defp subscribe(_,_,_), do: :ok

  defp unsubscribe(%{creator_id: creator_id, is_local: true, muted_at: nil}=follow) do
    context = Pointers.follow!(Repo.preload(follow, :context).context)
    case FeedSubscriptions.one(subscriber_id: creator_id, feed_id: context.outbox_id) do
      {:ok, sub} -> Common.soft_delete(sub)
      _ -> {:ok, []} # shouldn't be here
    end
  end

  defp valid_contexts() do
    Application.fetch_env!(:moodle_net, __MODULE__)
    |> Keyword.fetch!(:valid_contexts)
  end

end
