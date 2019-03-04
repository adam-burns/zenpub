defmodule MoodleNetWeb.GraphQL.ResourceResolver do
  import MoodleNetWeb.GraphQL.MoodleNetSchema

  alias MoodleNetWeb.GraphQL.Errors


  def like_resource(%{local_id: resource_id}, info) do
    with {:ok, liker} <- current_actor(info),
         {:ok, resource} <- fetch(resource_id, "MoodleNet:EducationalResource") do
      MoodleNet.like_resource(liker, resource)
    end
    |> Errors.handle_error()
  end

  def undo_like_resource(%{local_id: resource_id}, info) do
    with {:ok, actor} <- current_actor(info),
         {:ok, resource} <- fetch(resource_id, "MoodleNet:EducationalResource") do
      MoodleNet.undo_like(actor, resource)
    end
    |> Errors.handle_error()
  end

  def create_resource(%{resource: attrs, collection_local_id: col_id}, info) do
    with {:ok, actor} <- current_actor(info),
         {:ok, collection} <- fetch(col_id, "MoodleNet:Collection"),
         attrs = set_icon(attrs),
         {:ok, resource} = MoodleNet.create_resource(actor, collection, attrs) do
      fields = requested_fields(info)
      {:ok, prepare(resource, fields)}
    end
    |> Errors.handle_error()
  end

  def update_resource(%{resource: changes, resource_local_id: id}, info) do
    with {:ok, actor} <- current_actor(info),
         {:ok, resource} <- fetch(id, "MoodleNet:EducationalResource"),
         {:ok, resource} <- MoodleNet.update_resource(actor, resource, changes) do
      fields = requested_fields(info)
      {:ok, prepare(resource, fields)}
    end
    |> Errors.handle_error()
  end

  def delete_resource(%{local_id: id}, info) do
    with {:ok, author} <- current_actor(info),
         {:ok, resource} <- fetch(id, "MoodleNet:EducationalResource"),
         :ok <- MoodleNet.delete_resource(author, resource) do
      {:ok, true}
    end
    |> Errors.handle_error()
  end

  def copy_resource(attrs, info) do
    %{resource_local_id: res_id, collection_local_id: col_id} = attrs

    with {:ok, author} <- current_actor(info),
         {:ok, resource} <- fetch(res_id, "MoodleNet:EducationalResource"),
         {:ok, collection} <- fetch(col_id, "MoodleNet:Collection"),
         {:ok, resource_copy} <- MoodleNet.copy_resource(author, resource, collection) do
      fields = requested_fields(info)
      {:ok, prepare(resource_copy, fields)}
    end
    |> Errors.handle_error()
  end
end