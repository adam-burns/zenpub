# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Resources do
  alias Ecto.Changeset
  alias CommonsPub.{Activities, Common, Feeds, Flags, Likes, Repo, Threads}
  # alias CommonsPub.Collections.Collection
  # alias CommonsPub.FeedPublisher
  alias CommonsPub.Feeds.FeedActivities
  alias CommonsPub.Resources.{Resource, Queries}
  alias CommonsPub.Threads
  alias CommonsPub.Users.User
  alias CommonsPub.Workers.APPublishWorker

  alias CommonsPub.Utils.Web.CommonHelper

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

  @spec create(User.t(), any(), attrs :: map) ::
          {:ok, Resource.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, %{} = collection_or_context, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->
      collection_or_context =
        CommonHelper.maybe_preload(collection_or_context, :character)

      with {:ok, resource} <- insert_resource(creator, collection_or_context, attrs),
           {:ok, resource} <- ValueFlows.Util.try_tag_thing(creator, resource, attrs),
           act_attrs = %{
             verb: "created",
             is_local:
               is_nil(
                 CommonsPub.Utils.Web.CommonHelper.e(
                   collection_or_context,
                   :character,
                   :peer_id,
                   nil
                 )
               )
           },
           {:ok, activity} <- insert_activity(creator, resource, act_attrs),
           :ok <- publish(creator, collection_or_context, resource, activity),
           :ok <- ap_publish("create", resource) do
        CommonsPub.Search.Indexer.maybe_index_object(resource)
        {:ok, %Resource{resource | creator: creator}}
      end
    end)
  end

  def create(%User{} = creator, _, attrs) when is_map(attrs) do
    create(creator, attrs)
  end

  def create(%User{} = creator, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->
      with {:ok, resource} <- insert_resource(creator, attrs),
           {:ok, resource} <- ValueFlows.Util.try_tag_thing(creator, resource, attrs),
           act_attrs = %{
             verb: "created",
             is_local: is_nil(Map.get(creator.character, :peer_id, nil))
           },
           {:ok, activity} <- insert_activity(creator, resource, act_attrs),
           :ok <- publish(creator, resource, activity),
           :ok <- ap_publish("create", resource) do
        CommonsPub.Search.Indexer.maybe_index_object(resource)

        {:ok, %Resource{resource | creator: creator}}
      end
    end)
  end

  def clean_and_prepare_tags(%{summary: content} = attrs) when is_binary(content) do
    {content, mentions, hashtags} = CommonsPub.HTML.parse_input_and_tags(content, "text/markdown")

    # IO.inspect(tagging: {content, mentions, hashtags})

    attrs
    |> Map.put(:summary, content)
    |> Map.put(:mentions, mentions)
    |> Map.put(:hashtags, hashtags)
  end

  def clean_and_prepare_tags(attrs), do: attrs

  def save_attached_tags(creator, obj, attrs) do
    with {:ok, _taggable} <-
           CommonsPub.Tag.TagThings.thing_attach_tags(creator, obj, attrs.mentions) do
      # {:ok, CommonsPub.Repo.preload(comment, :tags)}
      {:ok, nil}
    end
  end

  defp insert_activity(creator, resource, attrs) do
    Activities.create(creator, resource, attrs)
  end

  defp insert_resource(creator, collection_or_context, attrs) do
    Repo.insert(Resource.create_changeset(creator, collection_or_context, attrs))
  end

  defp insert_resource(creator, attrs) do
    Repo.insert(Resource.create_changeset(creator, attrs))
  end

  @spec update(User.t(), Resource.t(), attrs :: map) ::
          {:ok, Resource.t()} | {:error, Changeset.t()}
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
  def soft_delete(%User{} = user, %Resource{} = resource) do
    Repo.transact_with(fn ->
      resource = Repo.preload(resource, [:context, collection: [:character]])

      with {:ok, deleted} <- Common.soft_delete(resource),
           :ok <- chase_delete(user, deleted.id),
           :ok <- ap_publish("delete", resource) do
        {:ok, deleted}
      end
    end)
  end

  def soft_delete_by(%User{} = user, filters) do
    with {:ok, _} <-
           Repo.transact_with(fn ->
             {_, ids} =
               update_by(user, [{:select, :id} | filters], deleted_at: DateTime.utc_now())

             with :ok <- chase_delete(user, ids) do
               ap_publish("delete", ids)
             end
           end),
         do: :ok
  end

  defp chase_delete(user, ids) do
    with :ok <- Activities.soft_delete_by(user, context: ids),
         :ok <- Flags.soft_delete_by(user, context: ids),
         :ok <- Likes.soft_delete_by(user, context: ids),
         :ok <- Threads.soft_delete_by(user, context: ids) do
      :ok
    end
  end

  defp publish(_creator, %{outbox_id: context_outbox}, _resource, activity) do
    # _community = Repo.preload(collection, :community).community
    feeds = [context_outbox, Feeds.instance_outbox_id()]
    FeedActivities.publish(activity, feeds)
  end

  defp publish(_creator, _context, _resource, activity) do
    feeds = [Feeds.instance_outbox_id()]
    FeedActivities.publish(activity, feeds)
  end

  defp publish(_creator, _resource, activity) do
    feeds = [Feeds.instance_outbox_id()]
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

  def indexing_object_format(%CommonsPub.Resources.Resource{} = resource) do
    resource = CommonHelper.maybe_preload(resource, :creator)
    resource = CommonHelper.maybe_preload(resource, :context)
    context = CommonHelper.maybe_preload(Map.get(resource, :context), :character)

    resource = CommonHelper.maybe_preload(resource, :content)

    likes_count =
      case CommonsPub.Likes.LikerCounts.one(context: resource.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = CommonsPub.Uploads.remote_url_from_id(resource.icon_id)
    resource_url = CommonsPub.Uploads.remote_url_from_id(resource.content_id)

    canonical_url = CommonsPub.ActivityPub.Utils.get_object_canonical_url(resource)

    %{
      "id" => resource.id,
      "name" => resource.name,
      "canonical_url" => canonical_url,
      "created_at" => resource.published_at,
      "icon" => icon,
      "licence" => Map.get(resource, :license),
      "likes" => %{
        "total_count" => likes_count
      },
      "summary" => Map.get(resource, :summary),
      "updated_at" => resource.updated_at,
      "index_type" => "Resource",
      "index_instance" => CommonsPub.Search.Indexer.host(canonical_url),
      "url" => resource_url,
      "author" => Map.get(resource, :author),
      "media_type" => resource.content.media_type,
      "subject" => Map.get(resource, :subject),
      "level" => Map.get(resource, :level),
      "language" => Map.get(resource, :language),
      "public_access" => Map.get(resource, :public_access),
      "free_access" => Map.get(resource, :free_access),
      "accessibility_feature" => Map.get(resource, :accessibility_feature),
      "context" => CommonsPub.Search.Indexer.maybe_indexable_object(context),
      "creator" => CommonsPub.Search.Indexer.format_creator(resource)
    }
  end
end
