# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Resources do
  alias Ecto.Changeset
  alias MoodleNet.{Activities, Common, Feeds, Flags, Likes, Repo, Threads}
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Feeds.FeedActivities
  alias MoodleNet.Resources.{Resource, Queries}
  alias MoodleNet.Threads
  alias MoodleNet.Users.User
  alias MoodleNet.Workers.APPublishWorker

  @doc """
  Retrieves a single resource by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for resources (inc. tests)
  """
  def one(filters), do: Repo.single(Queries.query(Resource, filters))

  @doc """
  Retrieves a list of resources by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for resources (inc. tests)
  """
  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Resource, filters))}

  ## and now the writes...

  @spec create(User.t(), Collection.t(), attrs :: map) ::
          {:ok, Resource.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, %Collection{} = collection, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->
      with {:ok, resource} <- insert_resource(creator, collection, attrs),
           act_attrs = %{verb: "created", is_local: is_nil(collection.actor.peer_id)},
           {:ok, activity} <- insert_activity(creator, resource, act_attrs),
           :ok <- publish(creator, collection, resource, activity),
           :ok <- ap_publish("create", resource) do
        {:ok, %Resource{resource | creator: creator}}
      end
    end)
  end


  defp insert_activity(creator, resource, attrs) do
    Activities.create(creator, resource, attrs)
  end

  defp insert_resource(creator, collection, attrs) do
    Repo.insert(Resource.create_changeset(creator, collection, attrs))
  end

  @spec update(User.t(), Resource.t(), attrs :: map) :: {:ok, Resource.t()} | {:error, Changeset.t()}
  def update(%User{}, %Resource{} = resource, attrs) when is_map(attrs) do
    with {:ok, updated} <- Repo.update(Resource.update_changeset(resource, attrs)),
         :ok <- ap_publish("update", resource) do
      {:ok, updated}
    end
  end

  def update_by(%User{}, filters, updates) do
    Repo.update_all(Queries.query(Resource, filters), set: updates)
  end

  @spec soft_delete(User.t(), Resource.t()) :: {:ok, Resource.t()} | {:error, Changeset.t()}
  def soft_delete(%User{}=user, %Resource{} = resource) do
    Repo.transact_with(fn ->
      resource = Repo.preload(resource, [collection: [:actor]])
      with {:ok, deleted} <- Common.soft_delete(resource),
           :ok <- chase_delete(user, deleted.id),
           :ok <- ap_publish("delete", resource) do
        {:ok, deleted}
      end
    end)
  end

  def soft_delete_by(%User{}=user, filters) do
    with {:ok, _} <-
      Repo.transact_with(fn ->
        {_, ids} = update_by(user, [{:select, :id} | filters], deleted_at: DateTime.utc_now())
        with :ok <- chase_delete(user, ids) do
          ap_publish("delete", ids)
        end
      end), do: :ok
  end

  defp chase_delete(user, ids) do
    with :ok <- Activities.soft_delete_by(user, context: ids),
         :ok <- Flags.soft_delete_by(user, context: ids),
         :ok <- Likes.soft_delete_by(user, context: ids),
         :ok <- Threads.soft_delete_by(user, context: ids) do
      :ok
    end
  end

  defp publish(_creator, collection, _resource, activity) do
    community = Repo.preload(collection, :community).community
    feeds = [collection.outbox_id, Feeds.instance_outbox_id()]
    FeedActivities.publish(activity, feeds)
  end

  defp ap_publish(verb, resources) when is_list(resources) do
    APPublishWorker.batch_enqueue(verb, resources)
    :ok
  end

  # todo: detect if local
  defp ap_publish(verb, %Resource{} = resource) do
    APPublishWorker.enqueue(verb, %{"context_id" => resource.id})
    :ok
  end

  defp ap_publish(_, _), do: :ok

end
