# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.CollectionsTest do
  use MoodleNet.DataCase, async: true

  import MoodleNet.Test.Faking
  alias MoodleNet.Common.NotFoundError
  alias MoodleNet.{Collections, Communities}
  alias MoodleNet.Test.Fake

  setup do
    user = fake_user!()
    community = fake_community!(user)
    collection = fake_collection!(user, community)
    {:ok, %{user: user, community: community, collection: collection}}
  end

  describe "count_for_list" do
    test "returns the number of public items", context do
      all = for _ <- 1..4 do
        user = fake_user!()
        comm = fake_community!(user)
        fake_collection!(user, comm)
      end ++ [context.collection]
      deleted = Enum.reduce(all, [], fn coll, acc ->
        if Fake.bool() do
          {:ok, coll} = Collections.soft_delete(coll)
          [coll | acc]
        else
          acc
        end
      end)

      assert Enum.count(all) - Enum.count(deleted) == Collections.count_for_list()
    end
  end

  describe "many" do
    test "returns a list of non-deleted collections", context do
      all = for _ <- 1..4 do
        user = fake_user!()
        comm = fake_community!(user)
        fake_collection!(user, comm)
      end ++ [context.collection]
      deleted = Enum.reduce(all, [], fn coll, acc ->
        if Fake.bool() do
          {:ok, coll} = Collections.soft_delete(coll)
          [coll | acc]
        else
          acc
        end
      end)
      {:ok, fetched} = Collections.many(:deleted)

      assert Enum.count(all) - Enum.count(deleted) == Enum.count(fetched)
      for coll <- fetched do
        assert coll.actor
        assert coll.follower_count
        refute coll.deleted_at
      end
    end

    test "ignores collections that have a deleted community", context do
      assert {:ok, comm} = Communities.soft_delete(context.community)

      # one of the collections is in context
      for _ <- 1..4 do
        user = fake_user!()
        fake_collection!(user, comm)
      end

      {:ok, fetched} = Collections.many(:deleted)
      assert Enum.empty?(fetched)
    end

    test "returns a list of collections in a community", context do
      collections = for _ <- 1..4 do
        user = fake_user!()
        fake_collection!(user, context.community)
      end ++ [context.collection]

      # create a one outside of the community
      user = fake_user!()
      fake_collection!(user, fake_community!(user))

      {:ok, fetched} = Collections.many(community_id: context.community.id)
      assert Enum.count(collections) == Enum.count(fetched)
    end
  end

  describe "one" do
    test "returns a collection by ID", context do
      assert {:ok, coll} = Collections.one(id: context.collection.id)
      assert coll.id == context.collection.id
      assert coll.actor
      assert coll.creator
    end

    test "fails when it has been deleted", context do
      assert {:ok, collection} = Collections.soft_delete(context.collection)
      assert {:error, %NotFoundError{}} = Collections.one([:deleted, id: context.collection.id])
    end

    test "fails when the parent community has been deleted", context do
      assert collection = fake_collection!(context.user, context.community)
      assert {:ok, _} = Communities.soft_delete(context.community)
      assert {:error, %NotFoundError{}} = Collections.one([:deleted, id: context.collection.id])
    end

    test "fails with a missing ID" do
      assert {:error, %NotFoundError{}} = Collections.one([id: Fake.ulid()])
    end
  end

  describe "create" do
    test "creates a new collection", context do
      attrs = Fake.collection()

      assert {:ok, collection} =
               Collections.create(context.user, context.community, attrs)

      assert collection.name == attrs.name
      assert collection.community_id == context.community.id
      assert collection.creator_id == context.user.id
      assert collection.actor
    end

    test "fails if given invalid attributes", context do
      assert {:error, changeset} =
               Collections.create(context.user, context.community, %{})
    end
  end

  describe "update" do
    test "updates a collection with the given attributes", %{collection: collection} do
      attrs = Fake.collection()
      assert {:ok, updated_collection} = Collections.update(collection, attrs)
      assert updated_collection.name == attrs.name
      assert updated_collection.actor.preferred_username == attrs.preferred_username
    end
  end

  describe "soft_delete" do
    test "works", context do
      refute context.collection.deleted_at
      assert {:ok, collection} = Collections.soft_delete(context.collection)
      assert collection.deleted_at
    end
  end

end
