# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.Algolia.Indexer do
  require Logger

  alias ActivityPub.HTTP
  alias MoodleNet.Repo
  alias MoodleNet.Resources.Resource
  alias MoodleNet.Communities.Community
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Follows.FollowerCounts
  alias MoodleNet.Likes.LikerCounts
  alias MoodleNet.Uploads

  defp check_envs() do
    System.get_env("ALGOLIA_ID") &&
      System.get_env("ALGOLIA_SECRET") &&
      System.get_env("ALGOLIA_INDEX")
  end

  defp supported_type(%Community{} = _object), do: true
  defp supported_type(%Collection{} = _object), do: true
  defp supported_type(%Resource{} = _object), do: true
  defp supported_type(_), do: false

  def maybe_index_object(object) do
    if check_envs() and supported_type(object) do # if Algolia is configured, use that
      object
      |> format_object()
      |> push_object() 
    else # otherwise use CommonsPub Search extension, powered by Meili
      if supported_type(object) do
        object
        |> format_object()
        |> Search.Indexer.maybe_index_object
      else
        Search.Indexer.maybe_index_object(object) 
      end
    end
  end

  def maybe_delete_object(object) do
    if check_envs() && supported_type(object) do
      object
      |> get_object_id()
      |> delete_object()
    else
      :ok
    end
  end

  def get_object_id(%Resource{} = object) do
    :crypto.hash(:sha, object.canonical_url) |> Base.encode16()
  end

  def get_object_id(object) do
    :crypto.hash(:sha, object.actor.canonical_url) |> Base.encode16()
  end

  def format_object(%Community{} = community) do
    follower_count =
      case FollowerCounts.one(context: community.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = Uploads.remote_url_from_id(community.icon_id)
    image = Uploads.remote_url_from_id(community.image_id)

    %{
      "index_mothership_object_id" => community.id,
      "canonicalUrl" => community.actor.canonical_url,
      "followers" => %{
        "totalCount" => follower_count
      },
      "icon" => icon,
      "image" => image,
      "name" => community.name,
      "preferredUsername" => community.actor.preferred_username,
      "summary" => Map.get(community, :summary),
      "index_type" => "Community",
      "index_instance" => URI.parse(community.actor.canonical_url).host,
      "createdAt" => community.published_at,
      "objectID" => :crypto.hash(:sha, community.actor.canonical_url) |> Base.encode16()
    }
  end

  def format_object(%Collection{} = collection) do
    collection = MoodleNet.Repo.preload(collection, community: [:actor])

    follower_count =
      case FollowerCounts.one(context: collection.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = Uploads.remote_url_from_id(collection.icon_id)

    %{
      "index_mothership_object_id" => collection.id,
      "canonicalUrl" => collection.actor.canonical_url,
      "followers" => %{
        "totalCount" => follower_count
      },
      "icon" => icon,
      "name" => collection.name,
      "preferredUsername" => collection.actor.preferred_username,
      "summary" => Map.get(collection, :summary),
      "index_type" => "Collection",
      "index_instance" => URI.parse(collection.actor.canonical_url).host,
      "createdAt" => collection.published_at,
      "community" => format_object(collection.community),
      "objectID" => :crypto.hash(:sha, collection.actor.canonical_url) |> Base.encode16()
    }
  end

  def format_object(%Resource{} = resource) do
    resource = Repo.preload(resource, [collection: [actor: [], community: [actor: []]], content: []])

    likes_count =
      case LikerCounts.one(context: resource.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = Uploads.remote_url_from_id(resource.icon_id)
    url = Uploads.remote_url_from_id(resource.content_id)

    %{
      "index_mothership_object_id" => resource.id,
      "name" => resource.name,
      "canonicalUrl" => resource.canonical_url,
      "createdAt" => resource.published_at,
      "icon" => icon,
      "licence" => Map.get(resource, :licence),
      "likes" => %{
        "totalCount" => likes_count
      },
      "summary" => Map.get(resource, :summary),
      "updatedAt" => resource.updated_at,
      "index_type" => "Resource",
      "index_instance" => URI.parse(resource.canonical_url).host,
      "collection" => format_object(resource.collection),
      "objectID" => :crypto.hash(:sha, resource.canonical_url) |> Base.encode16(),
      "url" => url,
      "author" => Map.get(resource, :author),
      "mediaType" => resource.content.media_type
    }
  end

  def push_object(object) do
    json = Jason.encode!(object)
    application_id = System.get_env("ALGOLIA_ID")
    api_key = System.get_env("ALGOLIA_SECRET")
    index_name = System.get_env("ALGOLIA_INDEX")
    url = "https://#{application_id}.algolia.net/1/indexes/#{index_name}/#{object["objectID"]}"

    headers = [
      {"X-Algolia-API-Key", api_key},
      {"X-Algolia-Application-id", application_id}
    ]

    with {:ok, %{status: code}} when code == 200 <- HTTP.put(url, json, headers) do
      :ok
    else
      {_, message} ->
        Logger.warn("Couldn't index object ID #{object["objectID"]}")
        Logger.warn(inspect(message))
        :ok
    end
  end

  def delete_object(object_id) do
    application_id = System.get_env("ALGOLIA_ID")
    api_key = System.get_env("ALGOLIA_SECRET")
    index_name = System.get_env("ALGOLIA_INDEX")
    url = "https://#{application_id}.algolia.net/1/indexes/#{index_name}/#{object_id}"

    headers = [
      {"X-Algolia-API-Key", api_key},
      {"X-Algolia-Application-id", application_id}
    ]

    with {:ok, %{status: code}} when code == 200 <- HTTP.delete(url, "", headers) do
      :ok
    else
      {_, message} ->
        Logger.warn("Couldn't index object ID #{object_id}")
        Logger.warn(inspect(message))
        :ok
    end
  end
end
