# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubTest do
  use MoodleNet.DataCase
  import ActivityPub.Factory
  alias ActivityPub.Actor
  alias ActivityPub.Object
  alias ActivityPub.Utils
  alias MoodleNet.Test.Faking

  doctest ActivityPub

  describe "create" do
    test "crates a create activity" do
      actor = insert(:actor)
      context = "blabla"
      object = %{"content" => "content", "type" => "Note"}
      to = ["https://testing.kawen.dance/users/karen"]

      params = %{
        actor: actor,
        context: context,
        object: object,
        to: to
      }

      {:ok, activity} = ActivityPub.create(params)

      assert actor.data["id"] == activity.data["actor"]
      assert activity.data["object"] == activity.object.data["id"]
    end
  end

  describe "following / unfollowing" do
    test "creates a follow activity" do
      follower = insert(:actor)
      followed = insert(:actor)

      {:ok, activity} = ActivityPub.follow(follower, followed)
      assert activity.data["type"] == "Follow"
      assert activity.data["actor"] == follower.data["id"]
      assert activity.data["object"] == followed.data["id"]
    end
  end

  test "creates an undo activity for the last follow" do
    follower = insert(:actor)
    followed = insert(:actor)

    {:ok, follow_activity} = ActivityPub.follow(follower, followed)
    {:ok, activity} = ActivityPub.unfollow(follower, followed)

    assert activity.data["type"] == "Undo"
    assert activity.data["actor"] == follower.data["id"]

    embedded_object = activity.data["object"]
    assert is_map(embedded_object)
    assert embedded_object["type"] == "Follow"
    assert embedded_object["object"] == followed.data["id"]
    assert embedded_object["id"] == follow_activity.data["id"]
  end

  describe "blocking / unblocking" do
    test "creates a block activity" do
      blocker = insert(:actor)
      blocked = insert(:actor)

      {:ok, activity} = ActivityPub.block(blocker, blocked)

      assert activity.data["type"] == "Block"
      assert activity.data["actor"] == blocker.data["id"]
      assert activity.data["object"] == blocked.data["id"]
    end

    test "creates an undo activity for the last block" do
      blocker = insert(:actor)
      blocked = insert(:actor)

      {:ok, block_activity} = ActivityPub.block(blocker, blocked)
      {:ok, activity} = ActivityPub.unblock(blocker, blocked)

      assert activity.data["type"] == "Undo"
      assert activity.data["actor"] == blocker.data["id"]

      embedded_object = activity.data["object"]
      assert is_map(embedded_object)
      assert embedded_object["type"] == "Block"
      assert embedded_object["object"] == blocked.data["id"]
      assert embedded_object["id"] == block_activity.data["id"]
    end
  end

  describe "deletion" do
    test "it creates a delete activity and deletes the original object" do
      actor = insert(:actor)
      context = "blabla"
      object = %{"content" => "content", "type" => "Note", "actor" => actor.data["id"]}
      to = ["https://testing.kawen.dance/users/karen"]

      params = %{
        actor: actor,
        context: context,
        object: object,
        to: to
      }

      {:ok, activity} = ActivityPub.create(params)
      object = activity.object
      {:ok, delete} = ActivityPub.delete(object)

      assert delete.data["type"] == "Delete"
      assert delete.data["actor"] == object.data["actor"]
      assert delete.data["object"] == object.data["id"]

      assert Object.get_by_id(delete.id) != nil

      assert Repo.get(Object, object.id).data["type"] == "Tombstone"
    end
  end

  describe "like an object" do
    test "adds a like activity to the db" do
      actor = Faking.fake_actor!()
      {:ok, note_actor} = Actor.get_by_username(actor.preferred_username)
      note_activity = insert(:note_activity, %{actor: note_actor})
      assert object = Object.normalize(note_activity)

      actor = insert(:actor)

      {:ok, like_activity, object} = ActivityPub.like(actor, object)

      assert like_activity.data["actor"] == actor.data["id"]
      assert like_activity.data["type"] == "Like"
      assert like_activity.data["object"] == object.data["id"]
      assert like_activity.data["to"] == [actor.data["followers"], note_activity.data["actor"]]
      assert like_activity.data["context"] == object.data["context"]

      # Just return the original activity if the user already liked it.
      {:ok, same_like_activity, _object} = ActivityPub.like(actor, object)

      assert like_activity == same_like_activity
    end
  end

  describe "unliking" do
    test "unliking a previously liked object" do
      actor = Faking.fake_actor!()
      {:ok, note_actor} = Actor.get_by_username(actor.preferred_username)
      note_activity = insert(:note_activity, %{actor: note_actor})
      object = Object.normalize(note_activity)
      actor = insert(:actor)

      # Unliking something that hasn't been liked does nothing
      {:ok, object} = ActivityPub.unlike(actor, object)

      {:ok, like_activity, object} = ActivityPub.like(actor, object)

      {:ok, _, _, _object} = ActivityPub.unlike(actor, object)

      assert Object.get_by_id(like_activity.id) == nil
    end
  end

  describe "announcing an object" do
    test "adds an announce activity to the db" do
      note_activity = insert(:note_activity)
      object = Object.normalize(note_activity)
      actor = insert(:actor)

      {:ok, announce_activity, object} = ActivityPub.announce(actor, object)

      assert announce_activity.data["to"] == [
               actor.data["followers"],
               note_activity.data["actor"]
             ]

      assert announce_activity.data["object"] == object.data["id"]
      assert announce_activity.data["actor"] == actor.data["id"]
      assert announce_activity.data["context"] == object.data["context"]
    end
  end

  describe "unannouncing an object" do
    test "unannouncing a previously announced object" do
      note_activity = insert(:note_activity)
      object = Object.normalize(note_activity)
      actor = insert(:actor)

      {:ok, announce_activity, object} = ActivityPub.announce(actor, object)

      {:ok, unannounce_activity, _object} = ActivityPub.unannounce(actor, object)

      assert unannounce_activity.data["to"] == [
               actor.data["followers"],
               announce_activity.data["actor"]
             ]

      assert unannounce_activity.data["type"] == "Undo"
      assert unannounce_activity.data["object"] == announce_activity.data
      assert unannounce_activity.data["actor"] == actor.data["id"]
      assert unannounce_activity.data["context"] == announce_activity.data["context"]

      assert Object.get_by_id(announce_activity.id) == nil
    end
  end

  describe "update" do
    test "it creates an update activity with the new user data" do
      actor = Faking.fake_actor!()
      {:ok, actor} = Actor.get_by_username(actor.preferred_username)
      {:ok, actor} = Actor.ensure_keys_present(actor)
      actor_data = ActivityPubWeb.ActorView.render("actor.json", %{actor: actor})

      {:ok, update} =
        ActivityPub.update(%{
          actor: actor_data["id"],
          to: [actor.data["followers"]],
          cc: [],
          object: actor_data
        })

      assert update.data["actor"] == actor.data["id"]
      assert update.data["to"] == [actor.data["followers"]]
      assert embedded_object = update.data["object"]
      assert embedded_object["id"] == actor_data["id"]
      assert embedded_object["type"] == actor_data["type"]
    end
  end

  test "it can create a Flag activity" do
    reporter = insert(:actor)
    target_account = insert(:actor)
    note_activity = insert(:note_activity, %{actor: target_account})
    context = Utils.generate_context_id()
    content = "foobar"

    reporter_ap_id = reporter.data["id"]
    target_ap_id = target_account.data["id"]
    activity_ap_id = note_activity.data["id"]

    assert {:ok, activity} =
             ActivityPub.flag(%{
               actor: reporter,
               context: context,
               account: target_account,
               statuses: [note_activity],
               content: content
             })

    assert %Object{
             data: %{
               "actor" => ^reporter_ap_id,
               "type" => "Flag",
               "content" => ^content,
               "context" => ^context,
               "object" => [^target_ap_id, ^activity_ap_id]
             }
           } = activity
  end
end
