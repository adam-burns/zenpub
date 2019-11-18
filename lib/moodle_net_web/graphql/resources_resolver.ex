# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.ResourcesResolver do
  alias MoodleNet.{Fake, Collections, GraphQL, Repo, Resources}
  alias MoodleNetWeb.GraphQL.{
    CollectionsResolver,
    CommonResolver,
    LocalisationResolver,
  }
  alias MoodleNet.Resources.Resource

  def resource(%{resource_id: id}, info), do: Resources.fetch(id)

  def is_public(%Resource{}=res, _, _), do: {:ok, not is_nil(res.published_at)}
  def is_disabled(%Resource{}=res, _, _), do: {:ok, not is_nil(res.disabled_at)}

  def resources(collection,_, info) do
    {:ok, Fake.long_edge_list(&Fake.resource/0)}
    |> GraphQL.response(info)
  end

  def create_resource(%{resource: attrs, collection_id: collection_id}, info) do
    with {:ok, current_user} <- GraphQL.current_user(info) do
      Repo.transact_with(fn ->
        with {:ok, collection} <- Collections.fetch(collection_id),
             {:ok, resource} <- Resources.create(collection, current_user, attrs) do
          {:ok, %{ resource | is_local: is_nil(collection.actor.peer_id) } }
        end
      end)
    end
  end

  def update_resource(%{resource: changes, resource_id: resource_id}, info) do
    with {:ok, current_user} <- GraphQL.current_user(info) do
      Repo.transact_with(fn ->
        with {:ok, resource} <- Resources.fetch(resource_id) do
          resource = Repo.preload(resource, [collection: :community])
          permitted? =
            current_user.local_user.is_instance_admin or
            resource.creator_id == current_user.id or
            resource.collection.creator_id == current_user.id or
            resource.collection.community.creator_id == current_user.id

          if permitted?,
            do: Resources.update(resource, changes),
            else: GraphQL.not_permitted()
        end
      end)
    end
  end

  def copy_resource(%{resource_id: resource_id, collection_id: collection_id}, info) do
    with {:ok, current_user} <- GraphQL.current_user(info) do
      Repo.transact_with(fn ->
        with {:ok, collection} <- Collections.fetch(collection_id),
             {:ok, resource} <- Resources.fetch(resource_id),
             attrs = Map.take(resource, ~w(name summary icon url license)a),
             {:ok, resource} <- Resources.create(collection, current_user, attrs) do
          {:ok, Map.put(resource, :is_local, true)}
        end
      end)
    end
  end

  def last_activity(_, _, info) do
    {:ok, Fake.past_datetime()}
    |> GraphQL.response(info)
  end

end
