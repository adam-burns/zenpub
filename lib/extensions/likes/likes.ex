# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Likes do
  alias CommonsPub.{Activities, Common, Repo}
  # alias CommonsPub.FeedPublisher
  alias CommonsPub.Feeds.FeedActivities
  alias CommonsPub.Likes.{AlreadyLikedError, Like, NotLikeableError, Queries}
  alias CommonsPub.Users.User
  alias CommonsPub.Workers.APPublishWorker

  def one(filters \\ []), do: Repo.single(Queries.query(Like, filters))

  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Like, filters))}

  def insert(%User{} = liker, liked, fields) do
    Repo.insert(Like.create_changeset(liker, liked, fields))
  end

  defp publish(creator, %{outbox_id: context_outbox_id}, %Like{} = like, verb) do
    attrs = %{verb: verb, is_local: like.is_local}

    with {:ok, activity} <- Activities.create(creator, like, attrs) do
      FeedActivities.publish(activity, [CommonsPub.Feeds.outbox_id(creator), context_outbox_id])
    end
  end

  defp publish(creator, _context, %Like{} = like, verb) do
    attrs = %{verb: verb, is_local: like.is_local}

    with {:ok, activity} <- Activities.create(creator, like, attrs) do
      FeedActivities.publish(activity, [CommonsPub.Feeds.outbox_id(creator)])
    end
  end

  defp ap_publish(verb, likes) when is_list(likes) do
    APPublishWorker.batch_enqueue(verb, likes)
    :ok
  end

  defp ap_publish(verb, %Like{is_local: true} = like) do
    APPublishWorker.enqueue(verb, %{"context_id" => like.id})
    :ok
  end

  defp ap_publish(_, _), do: :ok

  @doc """
  NOTE: assumes liked participates in meta, otherwise gives constraint error changeset
  """
  def create(liker, liked, fields)

  def create(%User{} = liker, %Pointers.Pointer{} = liked, fields) do
    create(liker, CommonsPub.Meta.Pointers.follow!(liked), fields)
  end

  def create(%User{} = liker, %{__struct__: ctx} = liked, fields) do
    if ctx in valid_contexts() do
      Repo.transact_with(fn ->
        case one(deleted: false, context: liked.id, creator: liker.id) do
          {:ok, _} ->
            {:error, AlreadyLikedError.new("user")}

          _ ->
            with {:ok, like} <- insert(liker, liked, fields),
                 :ok <- publish(liker, liked, like, "created"),
                 :ok <- ap_publish("create", like) do
              {:ok, like}
            end
        end
      end)
    else
      {:error, NotLikeableError.new(ctx)}
    end
  end

  def update(%User{}, %Like{} = like, fields) do
    Repo.update(Like.update_changeset(like, fields))
  end

  def update_by(%User{}, filters, updates) do
    Repo.update_all(Queries.query(Like, filters), set: updates)
  end

  @spec soft_delete(User.t(), Like.t()) :: {:ok, Like.t()} | {:error, any}
  def soft_delete(%User{} = user, %Like{} = like) do
    Repo.transact_with(fn ->
      with {:ok, like} <- Common.soft_delete(like),
           :ok <- chase_delete(user, like.id),
           :ok <- ap_publish("delete", like) do
        {:ok, like}
      end
    end)
  end

  def soft_delete_by(%User{} = user, filters) do
    with {:ok, _} <-
           Repo.transact_with(fn ->
             {_, ids} =
               update_by(user, [{:select, :id}, {:deleted, false} | filters],
                 deleted_at: DateTime.utc_now()
               )

             with :ok <- chase_delete(user, ids) do
               ap_publish("delete", ids)
             end
           end),
         do: :ok
  end

  defp chase_delete(user, ids) do
    Activities.soft_delete_by(user, context: ids)
  end

  defp valid_contexts() do
    CommonsPub.Config.get!(__MODULE__)
    |> Keyword.fetch!(:valid_contexts)
  end
end
