# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.ActivityPub.Adapter do
  alias MoodleNet.{Collections, Communities, Common, Repo, Resources, Threads, Users}
  alias MoodleNet.ActivityPub.Utils
  alias MoodleNet.Algolia.Indexer
  alias MoodleNet.Meta.Pointers
  alias MoodleNet.Threads.Comments
  alias MoodleNet.Users.User
  alias MoodleNet.Communities.Community
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Workers.APReceiverWorker
  require Logger

  @behaviour ActivityPub.Adapter

  def get_actor_by_username(username) do
    with {:error, _e} <- Users.one([:default, username: username]),
         {:error, _e} <- Communities.one([:default, username: username]),
         {:error, _e} <- Collections.one([:default, username: username]) do
      {:error, "not found"}
    end
  end

  def get_actor_by_id(id) do
    with {:error, _e} <- Users.one([:default, id: id]),
         {:error, _e} <- Communities.one([:default, id: id]),
         {:error, _e} <- Collections.one([:default, id: id]) do
      {:error, "not found"}
    end
  end

  def get_actor_by_ap_id(ap_id) do
    with {:ok, actor} <- ActivityPub.Actor.get_or_fetch_by_ap_id(ap_id),
         {:ok, actor} <- get_actor_by_username(actor.username) do
      {:ok, actor}
    else
      {:error, e} -> {:error, e}
    end
  end

  defp maybe_fix_image_object(url) when is_binary(url), do: url
  defp maybe_fix_image_object(%{"url" => url}), do: url
  defp maybe_fix_image_object(_), do: nil

  defp maybe_create_image_object(url, _actor) when is_nil(url), do: nil

  defp maybe_create_image_object(url, actor) do
    case MoodleNet.Uploads.upload(MoodleNet.Uploads.ImageUploader, actor, %{url: url}, %{}) do
      {:ok, upload} -> upload.id
      {:error, _} -> nil
    end
  end

  defp maybe_create_icon_object(url, _actor) when is_nil(url), do: nil

  defp maybe_create_icon_object(url, actor) do
    case MoodleNet.Uploads.upload(MoodleNet.Uploads.IconUploader, actor, %{url: url}, %{}) do
      {:ok, upload} -> upload.id
      {:error, _} -> nil
    end
  end

  # TODO: Rewrite this whole thing tbh
  def create_remote_actor(actor, username) do
    uri = URI.parse(actor["id"])
    ap_base = uri.scheme <> "://" <> uri.host

    peer =
      case Repo.get_by(MoodleNet.Peers.Peer, ap_url_base: ap_base) do
        nil ->
          {:ok, peer} = MoodleNet.Peers.create(%{ap_url_base: ap_base, domain: uri.host})
          peer

        peer ->
          peer
      end

    name =
      case actor["name"] do
        nil -> actor["preferredUsername"]
        "" -> actor["preferredUsername"]
        _ -> actor["name"]
      end

    icon_url = maybe_fix_image_object(actor["icon"])
    image_url = maybe_fix_image_object(actor["image"])

    create_attrs = %{
      preferred_username: username,
      name: name,
      summary: actor["summary"],
      is_public: true,
      is_local: false,
      is_disabled: false,
      peer_id: peer.id,
      canonical_url: actor["id"]
    }

    {:ok, created_actor, creator} =
      case actor["type"] do
        "Person" ->
          {:ok, created_actor} = MoodleNet.Users.register(create_attrs)
          {:ok, created_actor, created_actor}

        "MN:Community" ->
          {:ok, creator} = get_actor_by_ap_id(actor["attributedTo"])
          {:ok, created_actor} = MoodleNet.Communities.create_remote(creator, create_attrs)
          {:ok, created_actor, creator}

        "MN:Collection" ->
          {:ok, creator} = get_actor_by_ap_id(actor["attributedTo"])
          {:ok, community} = get_actor_by_ap_id(actor["context"])

          {:ok, created_actor} =
            MoodleNet.Collections.create_remote(creator, community, create_attrs)

          {:ok, created_actor, creator}
      end

    icon_id = maybe_create_icon_object(icon_url, creator)
    image_id = maybe_create_image_object(image_url, creator)

    {:ok, updated_actor} =
      case created_actor do
        %MoodleNet.Users.User{} ->
          Users.update_remote(created_actor, %{icon_id: icon_id, image_id: image_id})

        %MoodleNet.Communities.Community{} ->
          Communities.update(%User{}, created_actor, %{icon_id: icon_id, image_id: image_id})

        %MoodleNet.Collections.Collection{} ->
          Collections.update(%User{}, created_actor, %{icon_id: icon_id, image_id: image_id})
      end

    object = ActivityPub.Object.get_cached_by_ap_id(actor["id"])

    ActivityPub.Object.update(object, %{mn_pointer_id: created_actor.id})
    Indexer.maybe_index_object(updated_actor)
    {:ok, updated_actor}
  end

  def update_local_actor(actor, params) do
    with {:ok, local_actor} <-
           CommonsPub.Character.Characters.one(username: actor.data["preferredUsername"]),
         {:ok, local_actor} <-
           CommonsPub.Character.Characters.update(%User{}, local_actor, params),
         {:ok, local_actor} <- get_actor_by_username(local_actor.preferred_username) do
      {:ok, local_actor}
    else
      {:error, e} -> {:error, e}
    end
  end

  def update_user(actor, data) do
    with params <- %{
           name: data["name"],
           summary: data["summary"],
           icon_id: maybe_create_icon_object(maybe_fix_image_object(data["icon"]), actor),
           image_id: maybe_create_image_object(maybe_fix_image_object(data["image"]), actor)
         },
         {:ok, user} <- MoodleNet.Users.update_remote(actor, params) do
      {:ok, user}
    else
      {:error, e} -> {:error, e}
    end
  end

  def update_community(actor, data) do
    with {:ok, creator} <- Users.one([:default, id: actor.creator_id]),
         params <- %{
           name: data["name"],
           summary: data["summary"],
           icon_id: maybe_create_icon_object(maybe_fix_image_object(data["icon"]), creator),
           image_id: maybe_create_image_object(maybe_fix_image_object(data["image"]), creator)
         },
         {:ok, comm} <- MoodleNet.Communities.update(creator, actor, params) do
      {:ok, comm}
    else
      {:error, e} -> {:error, e}
    end
  end

  def update_collection(actor, data) do
    with {:ok, creator} <- Users.one([:default, id: actor.creator_id]),
         params <- %{
           name: data["name"],
           summary: data["summary"],
           icon_id: maybe_create_icon_object(maybe_fix_image_object(data["icon"]), creator)
         },
         {:ok, coll} <- MoodleNet.Collections.update(creator, actor, params) do
      {:ok, coll}
    else
      {:error, e} -> {:error, e}
    end
  end

  def update_remote_actor(actor_object) do
    data = actor_object.data

    with {:ok, actor} <- get_actor_by_id(actor_object.mn_pointer_id) do
      case actor do
        %MoodleNet.Users.User{} ->
          update_user(actor, data)

        %MoodleNet.Communities.Community{} ->
          update_community(actor, data)

        %MoodleNet.Collections.Collection{} ->
          update_collection(actor, data)
      end
    end
  end

  def maybe_create_remote_actor(actor) do
    host = URI.parse(actor.data["id"]).host
    username = actor.data["preferredUsername"] <> "@" <> host

    case CommonsPub.Character.Characters.one(username: username) do
      {:error, _} ->
        with {:ok, _actor} <- create_remote_actor(actor.data, username) do
          :ok
        else
          _e -> {:error, "Couldn't create remote actor"}
        end

      _ ->
        :ok
    end
  end

  def handle_activity(activity) do
    APReceiverWorker.enqueue("handle_activity", %{
      "activity_id" => activity.id,
      "activity" => activity.data
    })
  end

  def handle_create(
        _activity,
        %{data: %{"type" => "Note", "inReplyTo" => in_reply_to}} = object
      )
      when not is_nil(in_reply_to) do
    # This will fail if the reply isn't in database
    with parent_id <- Utils.get_pointer_id_by_ap_id(in_reply_to),
         {:ok, parent_comment} <- Comments.one(id: parent_id),
         {:ok, thread} <- Threads.one(id: parent_comment.thread_id),
         {:ok, actor} <- get_actor_by_ap_id(object.data["actor"]),
         {:ok, comment} <-
           Comments.create_reply(actor, thread, parent_comment, %{
             is_public: object.public,
             content: object.data["content"],
             is_local: false,
             canonical_url: object.data["id"]
           }) do
      ActivityPub.Object.update(object, %{mn_pointer_id: comment.id})
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def handle_create(
        %{data: %{"context" => context}} = _activity,
        %{data: %{"type" => "Note"}} = object
      ) do
    with pointer_id <- MoodleNet.ActivityPub.Utils.get_pointer_id_by_ap_id(context),
         {:ok, pointer} <- Pointers.one(id: pointer_id),
         parent = MoodleNet.Meta.Pointers.follow!(pointer),
         {:ok, actor} <- get_actor_by_ap_id(object.data["actor"]),
         {:ok, thread} <- Threads.create(actor, parent, %{is_public: true, is_local: false}),
         {:ok, comment} <-
           Comments.create(actor, thread, %{
             is_public: object.public,
             content: object.data["content"],
             is_local: false,
             canonical_url: object.data["id"]
           }) do
      ActivityPub.Object.update(object, %{mn_pointer_id: comment.id})
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def handle_create(
        %{data: %{"context" => context}} = _activity,
        %{data: %{"type" => "Document", "actor" => actor}} = object
      ) do
    with {:ok, collection} <- get_actor_by_ap_id(context),
         {:ok, actor} <- get_actor_by_ap_id(actor),
         {:ok, content} <-
           MoodleNet.Uploads.upload(
             MoodleNet.Uploads.ResourceUploader,
             actor,
             %{url: object.data["url"]},
             %{is_public: true}
           ),
         icon_url <- maybe_fix_image_object(object.data["icon"]),
         icon_id <- maybe_create_icon_object(icon_url, actor),
         attrs <- %{
           is_public: true,
           is_local: false,
           is_disabled: false,
           name: object.data["name"],
           canonical_url: object.data["id"],
           summary: object.data["summary"],
           content_id: content.id,
           license: object.data["tag"],
           icon_id: icon_id,
           author: Utils.get_author(object.data["author"]),
           subject: object.data["subject"],
           level: object.data["level"],
           language: object.data["language"]
         },
         {:ok, resource} <-
           MoodleNet.Resources.create(actor, collection, attrs) do
      ActivityPub.Object.update(object, %{mn_pointer_id: resource.id})
      # Indexer.maybe_index_object(resource) # now being called in MoodleNet.Resources.create
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def handle_create(_activity, object) do
    Logger.info("Unhandled object type: #{object.data["type"]}")
    :ok
  end

  def perform(
        :handle_activity,
        %{
          data: %{
            "type" => "Create",
            "object" => object_id
          }
        } = activity
      ) do
    object = ActivityPub.Object.get_cached_by_ap_id(object_id)
    handle_create(activity, object)
  end

  def perform(:handle_activity, %{data: %{"type" => "Follow"}} = activity) do
    with {:ok, follower} <- get_actor_by_ap_id(activity.data["actor"]),
         {:ok, followed} <- get_actor_by_ap_id(activity.data["object"]),
         {:ok, _} <-
           MoodleNet.Follows.create(follower, followed, %{
             is_public: true,
             is_muted: false,
             is_local: false,
             canonical_url: activity.data["id"]
           }) do
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def perform(
        :handle_activity,
        %{data: %{"type" => "Undo", "object" => %{"type" => "Follow"}}} = activity
      ) do
    with {:ok, follower} <- get_actor_by_ap_id(activity.data["object"]["actor"]),
         {:ok, followed} <- get_actor_by_ap_id(activity.data["object"]["object"]),
         {:ok, follow} <-
           MoodleNet.Follows.one(deleted: false, creator: follower.id, context: followed.id),
         {:ok, _} <- MoodleNet.Follows.soft_delete(follower, follow) do
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def perform(:handle_activity, %{data: %{"type" => "Block"}} = activity) do
    with {:ok, blocker} <- get_actor_by_ap_id(activity.data["actor"]),
         {:ok, blocked} <- get_actor_by_ap_id(activity.data["object"]),
         {:ok, _} <-
           MoodleNet.Blocks.create(blocker, blocked, %{
             is_public: true,
             is_muted: false,
             is_blocked: true,
             is_local: false,
             canonical_url: activity.data["id"]
           }) do
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def perform(
        :handle_activity,
        %{data: %{"type" => "Undo", "object" => %{"type" => "Block"}}} = activity
      ) do
    with {:ok, blocker} <- get_actor_by_ap_id(activity.data["object"]["actor"]),
         {:ok, blocked} <- get_actor_by_ap_id(activity.data["object"]["object"]),
         {:ok, block} <- MoodleNet.Blocks.find(blocker, blocked),
         {:ok, _} <- MoodleNet.Blocks.soft_delete(blocker, block) do
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def perform(:handle_activity, %{data: %{"type" => "Like"}} = activity) do
    with {:ok, ap_actor} <- ActivityPub.Actor.get_by_ap_id(activity.data["actor"]),
         {:ok, actor} <- get_actor_by_username(ap_actor.username),
         %ActivityPub.Object{} = object <-
           ActivityPub.Object.get_cached_by_ap_id(activity.data["object"]),
         {:ok, liked} <- Pointers.one(id: object.mn_pointer_id),
         liked = MoodleNet.Meta.Pointers.follow!(liked),
         {:ok, _} <-
           MoodleNet.Likes.create(actor, liked, %{
             is_public: true,
             is_local: false,
             canonical_url: activity.data["id"]
           }) do
      :ok
    else
      {:error, e} -> {:error, e}
    end
  end

  def perform(
        :handle_activity,
        %{data: %{"type" => "Delete", "object" => obj_id}} = activity
      ) do
    object = ActivityPub.Object.get_cached_by_ap_id(obj_id)

    if object.data["type"] in ["Person", "MN:Community", "MN:Collection", "Group"] do
      with {:ok, actor} <- get_actor_by_ap_id(activity.data["object"]),
           {:ok, _} <-
             (case actor do
                %User{} -> MoodleNet.Users.soft_delete_remote(actor)
                %Community{} -> MoodleNet.Communities.soft_delete(%User{}, actor)
                %Collection{} -> MoodleNet.Collections.soft_delete(%User{}, actor)
              end) do
        Indexer.maybe_delete_object(actor)
        :ok
      else
        {:error, e} ->
          {:error, e}
      end
    else
      case object.data["formerType"] do
        "Note" ->
          with {:ok, comment} <- Comments.one(id: object.mn_pointer_id),
               {:ok, _} <- Common.soft_delete(comment) do
            :ok
          end

        "Document" ->
          with {:ok, resource} <- Resources.one(id: object.mn_pointer_id),
               {:ok, _} <- Common.soft_delete(resource) do
            Indexer.maybe_delete_object(resource)
            :ok
          end
      end
    end
  end

  def perform(
        :handle_activity,
        %{data: %{"type" => "Update", "object" => %{"id" => ap_id}}} = _activity
      ) do
    with {:ok, actor} <- ActivityPub.Actor.get_cached_by_ap_id(ap_id),
         {:ok, actor} <- update_remote_actor(actor) do
      Indexer.maybe_index_object(actor)
      :ok
    end
  end

  def perform(:handle_activity, %{data: %{"type" => "Flag", "object" => objects}} = activity)
      when length(objects) > 1 do
    with {:ok, actor} <- get_actor_by_ap_id(activity.data["actor"]) do
      activity.data["object"]
      |> Enum.map(fn ap_id -> ActivityPub.Object.get_cached_by_ap_id(ap_id) end)
      # Filter nils
      |> Enum.filter(fn object -> object end)
      |> Enum.map(fn object ->
        MoodleNet.Meta.Pointers.one!(id: object.mn_pointer_id)
        |> MoodleNet.Meta.Pointers.follow!()
      end)
      |> Enum.each(fn object ->
        MoodleNet.Flags.create(actor, object, %{
          message: activity.data["content"],
          is_local: false
        })
      end)

      :ok
    end
  end

  def perform(:handle_activity, %{data: %{"type" => "Flag", "object" => [account]}} = activity) do
    with {:ok, actor} <- get_actor_by_ap_id(activity.data["actor"]),
         {:ok, account} <- get_actor_by_ap_id(account) do
      MoodleNet.Flags.create(actor, account, %{
        message: activity.data["content"],
        is_local: false
      })

      :ok
    end
  end

  def perform(:handle_activity, activity) do
    Logger.info("Unhandled activity type: #{activity.data["type"]}")
    :ok
  end
end
