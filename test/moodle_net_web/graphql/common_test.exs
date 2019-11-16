# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.CommonTest do
  use MoodleNetWeb.ConnCase, async: true
  alias MoodleNet.{Common,Access}
  # import MoodleNet.MediaProxy.URLBuilder, only: [encode: 1]
  import MoodleNetWeb.Test.GraphQLAssertions
  # import MoodleNet.Test.Faking
  # import MoodleNetWeb.Test.ConnHelpers
  # import MoodleNetWeb.Test.GraphQLAssertions

  @create_flag_q """
  mutation Test($contextId: String!, $message: String!) {
    flag(contextId: $contextId, message: $message) {
      id canonicalUrl isLocal isPublic message isResolved createdAt updatedAt
    }
  }
  """
  @create_follow_q """
  mutation Test($contextId: String!) {
    follow(contextId: $contextId) {
      id canonicalUrl isLocal isPublic createdAt
    }
  }
  """
  @create_like_q """
  mutation Test($contextId: String!) {
    like(contextId: $contextId) {
      id canonicalUrl isLocal isPublic createdAt
    }
  }
  """
  @create_tagging_q """
  mutation Test($contextId: String!, $tagId: String!) {
    tag(contextId: $contextId, tagId: $tagId) {
      id isLocal isPublic createdAt
    }
  }
  """
  @delete_q """
  mutation Test($contextId: String!) {
    delete(contextId: $contextId)
  }
  """
  describe "create_flag" do
    test "works" do
      vars = %{"contextId" => "c", "message" => "m"}
      query = %{operationName: "Test", query: @create_flag_q, variables: vars}
      assert %{"flag" => flag} = gql_post_data(json_conn(),query)
      assert_flag(flag)
    end
  end
  describe "create_follow" do
    test "works" do
      vars = %{"contextId" => ""}
      query = %{operationName: "Test", query: @create_follow_q, variables: vars}
      assert %{"follow" => follow} = gql_post_data(json_conn(),query)
      assert_follow(follow)
    end
  end
  describe "create_like" do
    test "works" do
      vars = %{"contextId" => ""}
      query = %{operationName: "Test", query: @create_like_q, variables: vars}
      assert %{"like" => like} = gql_post_data(json_conn(),query)
      assert_like(like)
    end
  end
  describe "delete" do
    test "works" do
      vars = %{"contextId" => ""}
      query = %{operationName: "Test", query: @delete_q, variables: vars}
      assert %{"delete" => true} = gql_post_data(json_conn(),query)
    end
  end

  describe "tag" do
    test "for a tagging" do
    end
  end
  describe "context" do
    test "for a like" do
    end
    test "for a flag" do
    end
    test "for a follow" do
    end
    # test "for a tagging" do
    # end
  end
  describe "my_follow" do
    test "for a user" do
    end
    test "for a community" do
    end
    test "for a collection" do
    end
    test "for a thread" do
    end
  end
  describe "my_like" do
    test "for a collection" do
    end
    test "for a resource" do
    end
    test "for a comment" do
    end
  end
  describe "followers" do
    test "for a user" do
    end
    test "for a community" do
    end
    test "for a thread" do
    end
  end
  describe "likes" do
    test "for a collection" do
    end
    test "for a resource" do
    end
    test "for a comment" do
    end
  end
  describe "flags" do
    test "for a user" do
    end
    test "for a community" do
    end
    test "for a collection" do
    end
    test "for a resource" do
    end
    test "for a comment" do
    end
    test "for a thread" do
    end
  end

  # describe "tags" do
  # end

  # describe "create_tagging" do
  #   test "works" do
  #     vars = %{"contextId" => "", "tagId" => ""}
  #     query = %{operationName: "Test", query: @create_tagging_q, variables: vars}
  #     assert %{"tag" => tagging} = gql_post_data(json_conn(),query)
  #     assert_tagging(tagging)
  #   end
  # end

  # defp assert_already_liked(errs, path) do
  #   assert [err] = errs
  #   assert %{"code" => code, "message" => message} = err
  #   assert %{"path" => ^path, "locations" => [loc]} = err
  #   assert code == "already_liked"
  #   assert message == "already liked"
  #   assert_location(loc)
  # end

  # defp assert_already_following(errs, path) do
  #   assert [err] = errs
  #   assert %{"code" => code, "message" => message} = err
  #   assert %{"path" => ^path, "locations" => [loc]} = err
  #   assert code == "already_following"
  #   assert message == "already following"
  #   assert_location(loc)
  # end

  # defp assert_already_flagged(errs, path) do
  #   assert [err] = errs
  #   assert %{"code" => code, "message" => message} = err
  #   assert %{"path" => ^path, "locations" => [loc]} = err
  #   assert code == "already_flagged"
  #   assert message == "already flagged"
  #   assert_location(loc)
  # end


  # describe "CommonResolver.like" do

  #   @tag :skip
  #   test "Works for a collection" do
  #   end

  #   @tag :skip
  #   test "Works for a comment" do
  #   end

  #   @tag :skip
  #   test "Works for a resource" do
  #   end

  #   @tag :skip
  #   test "Does not work for a guest" do
  #   end

  # end

  # describe "CommonResolver.undo_like" do

  #   @tag :skip
  #   test "Does not work for a guest" do
  #   end

  #   @tag :skip
  #   test "Works for a collection" do
  #   end

  #   @tag :skip
  #   test "Works for a comment" do
  #   end

  #   @tag :skip
  #   test "Works for a resource" do
  #   end

  # end

  # describe "CommonResolver.flag" do

  #   test "Does not work for a guest" do
  #     bob = fake_user!()
  #     query = """
  #     mutation { flag(
  #        contextId: "#{bob.actor.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert_not_logged_in(gql_post_errors(%{query: query}), ["flag"])
  #   end

  #   test "Works for a user" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{bob.actor.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_already_flagged(errs, ["flag"])
  #   end

  #   test "Works for a community" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     comm = fake_community!(bob)
      
  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{comm.actor.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_already_flagged(errs, ["flag"])
  #   end

  #   # TODO: test inserts community id
  #   test "Works for a collection" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     comm = fake_community!(bob)
  #     coll = fake_collection!(bob, comm)
  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{coll.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_already_flagged(errs, ["flag"])
  #   end

  #   # TODO: test inserts community id
  #   test "Works for a resource" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     comm = fake_community!(bob)
  #     coll = fake_collection!(bob, comm)
  #     res = fake_resource!(bob, coll)
  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{res.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_already_flagged(errs, ["flag"])
  #   end

  #   @tag :skip
  #   test "Works for a comment" do
  #     # assert errs == gql_post_errors(conn, %{query: query})
  #     # assert_already_flagged(errs, ["flag"])
  #   end

  # end

  # describe "CommonResolver.undo_flag" do

  #   test "Does not work for a guest" do
  #     bob = fake_user!()
  #     query = """
  #     mutation { undoFlag(contextId: "#{bob.actor.id}") }
  #     """
  #     assert_not_logged_in(gql_post_errors(%{query: query}), ["undoFlag"])
  #   end

  #   test "Works unflagging a user" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)

  #     query = """
  #     mutation {
  #       undoFlag(contextId: "#{bob.actor.id}")
  #     }
  #     """
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errs, ["undoFlag"])

  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{bob.actor.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")

  #     query = """
  #     mutation {
  #       undoFlag(contextId: "#{bob.actor.id}")
  #     }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "undoFlag")
  #   end

  #   test "Works unflagging a community" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     comm = fake_community!(bob)
      
  #     query = """
  #     mutation {
  #       undoFlag(contextId: "#{comm.actor.id}")
  #     }
  #     """
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errs, ["undoFlag"])

  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{comm.actor.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")

  #     query = """
  #     mutation {
  #       undoFlag(contextId: "#{comm.actor.id}")
  #     }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "undoFlag")
  #   end

  #   # TODO: test inserts community id
  #   test "Works unflagging a collection" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     comm = fake_community!(bob)
  #     coll = fake_collection!(bob, comm)

  #     query = """
  #     mutation { undoFlag(contextId: "#{coll.id}") }
  #     """
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errs, ["undoFlag"])

  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{coll.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")

  #     query = """
  #     mutation { undoFlag(contextId: "#{coll.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "undoFlag")
  #   end

  #   # TODO: test inserts community id
  #   test "Works unflagging a resource" do
  #     alice = fake_user!()
  #     bob = fake_user!()
  #     conn = user_conn(alice)
  #     comm = fake_community!(bob)
  #     coll = fake_collection!(bob, comm)
  #     res = fake_resource!(bob, coll)

  #     query = """
  #     mutation { undoFlag(contextId: "#{res.id}") }
  #     """
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errs, ["undoFlag"])

  #     query = """
  #     mutation {
  #       flag(
  #        contextId: "#{res.id}"
  #        reason: "abusive"
  #       ) }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "flag")

  #     query = """
  #     mutation { undoFlag(contextId: "#{res.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "undoFlag")
  #   end

  #   @tag :skip
  #   test "Works unflagging a comment" do
  #     # assert errs == gql_post_errors(conn, %{query: query})
  #     # assert_already_flagged(errs, ["flag"])
  #   end

  # end

  # describe "CommonResolver.follow" do

  #   test "works for following a community" do
  #     alice = fake_user!()
  #     community = fake_community!(alice)
  #     bob = fake_user!()
  #     conn = user_conn(bob)
  #     query = """
  #     mutation { follow(contextId: "#{community.actor.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "follow")
  #     assert {:ok, _} = Common.find_follow(bob.actor, community.actor)
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_already_following(errs, ["follow"])
  #   end

  #   test "works for following a collection" do
  #     alice = fake_user!()
  #     community = fake_community!(alice)
  #     collection = fake_collection!(alice, community)
  #     bob = fake_user!()
  #     conn = user_conn(bob)
  #     query = """
  #     mutation { follow(contextId: "#{collection.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "follow")
  #     assert {:ok, _} = Common.find_follow(bob.actor, collection)
  #     assert errs = gql_post_errors(conn, %{query: query})
  #     assert_already_following(errs, ["follow"])
  #   end

  #   @tag :skip
  #   test "works for following a thread" do
  #     # alice = fake_user!()
  #     # community = fake_community!(alice)
  #     # collection = fake_collection!(alice, community)
  #     # bob = fake_user!()
  #     # conn = user_conn(bob)
  #     # query = """
  #     # mutation { follow(contextId: "#{collection.id}") }
  #     # """
  #     # assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "follow")
  #     # assert {:ok, _} = Common.find_follow(bob.actor, collection)
  #     # assert errs = gql_post_errors(conn, %{query: query})
  #     # assert_already_following(errs, ["follow"])
  #   end

  #   test "doesn't work for a guest" do
  #     user = fake_user!()
  #     community = fake_community!(user)
  #     query = """
  #     mutation { follow(contextId: "#{community.actor.id}") }
  #     """
  #     assert errors = gql_post_errors(json_conn(), %{query: query})
  #     assert_not_logged_in(errors, ["follow"])
  #   end

  # end

  # describe "CommonResolver.undo_follow" do

  #   test "Does not work for a guest" do
  #     alice = fake_user!()
  #     community = fake_community!(alice)
  #     query = """
  #     mutation { undoFollow(contextId: "#{community.actor.id}") }
  #     """
  #     assert errors = gql_post_errors(json_conn(), %{query: query})
  #     assert_not_logged_in(errors, ["undoFollow"])
  #   end

  #   test "Works unfollowing a community" do
  #     alice = fake_user!()
  #     community = fake_community!(alice)
  #     bob = fake_user!()
  #     conn = user_conn(bob)

  #     query = """
  #     mutation { undoFollow(contextId: "#{community.actor.id}") }
  #     """
  #     assert errors = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errors, ["undoFollow"])

  #     query = """
  #     mutation { follow(contextId: "#{community.actor.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "follow")

  #     query = """
  #     mutation { undoFollow(contextId: "#{community.actor.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "undoFollow")
  #     assert errors = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errors, ["undoFollow"])
  #   end

  #   # TODO: test inserts community id
  #   test "Works unfollowing a collection" do
  #     alice = fake_user!()
  #     community = fake_community!(alice)
  #     collection = fake_collection!(alice, community)
  #     bob = fake_user!()
  #     conn = user_conn(bob)

  #     query = """
  #     mutation { undoFollow(contextId: "#{collection.id}") }
  #     """
  #     assert errors = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errors, ["undoFollow"])

  #     query = """
  #     mutation { follow(contextId: "#{collection.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "follow")

  #     query = """
  #     mutation { undoFollow(contextId: "#{collection.id}") }
  #     """
  #     assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "undoFollow")
  #     assert errors = gql_post_errors(conn, %{query: query})
  #     assert_not_found(errors, ["undoFollow"])
  #   end

  #   @tag :skip
  #   test "Works unfollowing a thread" do
  #     # alice = fake_user!()
  #     # community = fake_community!(alice)
  #     # query = """
  #     # mutation { follow(contextId: "#{thread.id}") }
  #     # """
  #     # assert true == Map.fetch!(gql_post_data(conn, %{query: query}), "follow")
  #     # query = """
  #     # mutation { undoFollow(contextId: "#{thread.id}") }
  #     # """
  #     # assert errs = gql_post_errors(conn, %{query: query})
  #     # assert_already_flagged(errs, ["flag"])
  #   end

  # end

end
