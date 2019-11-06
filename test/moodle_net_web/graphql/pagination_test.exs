# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.PaginationTest do
  use MoodleNetWeb.ConnCase, async: true

  # import ActivityPub.Entity, only: [local_id: 1]
  # @moduletag format: :json

  # @tag :user
  # test "paginates by creation", %{conn: conn, actor: actor} do
  #   a = Factory.community(actor)
  #   b = Factory.community(actor)

  #   query = """
  #   {
  #     communities {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => nil,
  #              "endCursor" => nil
  #            },
  #            "nodes" => [b_map, a_map]
  #          } = community_page

  #   assert a_map == %{
  #     "id" => a.id,
  #     "localId" => local_id(a),
  #     "name" => a.name["und"]
  #   }

  #   assert b_map == %{
  #     "id" => b.id,
  #     "localId" => local_id(b),
  #     "name" => b.name["und"]
  #   }

  #   query = """
  #   {
  #     communities(limit: 1) {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => nil,
  #              "endCursor" => cursor
  #            },
  #            "nodes" => [^b_map]
  #          } = community_page

  #   query = """
  #   {
  #     communities(limit: 1, after: #{cursor}) {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => cursor
  #            },
  #            "nodes" => [^a_map]
  #          } = community_page

  #   query = """
  #   {
  #     communities(limit: 1, after: #{cursor}) {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => nil
  #            },
  #            "nodes" => []
  #          } = community_page

  #   query = """
  #   {
  #     communities(limit: 1, before: #{cursor}) {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => cursor
  #            },
  #            "nodes" => [^a_map]
  #          } = community_page

  #   query = """
  #   {
  #     communities(limit: 1, before: #{cursor}) {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => cursor
  #            },
  #            "nodes" => [^b_map]
  #          } = community_page

  #   query = """
  #   {
  #     communities(limit: 1, before: #{cursor}) {
  #       pageInfo {
  #         startCursor
  #         endCursor
  #       }
  #       nodes {
  #         id
  #         localId
  #         name
  #       }
  #     }
  #   }
  #   """

  #   assert community_page =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("communities")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => nil,
  #              "endCursor" => cursor
  #            },
  #            "nodes" => []
  #          } = community_page

  #   assert cursor
  # end

  # @tag :user
  # test "paginates by collection insertion", %{conn: conn, actor: actor} do
  #   community = Factory.community(actor)
  #   comm_local_id = local_id(community)

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members(limit: 1) {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #         edges {
  #           cursor
  #           node {
  #             id
  #             localId
  #             name
  #           }
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => nil,
  #              "endCursor" => cursor
  #            },
  #            "edges" => [
  #              %{
  #                "cursor" => cursor,
  #                "node" => actor_map
  #              }
  #            ]
  #          } = community_map["members"]

  #   assert actor_map == %{
  #            "id" => actor.id,
  #            "name" => actor.name["und"],
  #            "localId" => local_id(actor)
  #          }

  #   other_actor = Factory.actor()
  #   MoodleNet.join_community(other_actor, community)

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => nil,
  #              "endCursor" => cursor
  #            },
  #            "edges" => [
  #              %{
  #                "cursor" => cursor,
  #                "node" => other_actor_map
  #              }
  #            ]
  #          } = community_map["members"]

  #   assert cursor

  #   assert other_actor_map == %{
  #            "id" => other_actor.id,
  #            "name" => other_actor.name["und"],
  #            "localId" => local_id(other_actor)
  #          }

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members(limit: 1, after: #{cursor}) {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #         edges {
  #           cursor
  #           node {
  #             id
  #             localId
  #             name
  #           }
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => cursor
  #            },
  #            "edges" => [
  #              %{
  #                "cursor" => cursor,
  #                "node" => ^actor_map
  #              }
  #            ]
  #          } = community_map["members"]

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members(limit: 1, after: #{cursor}) {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #         edges {
  #           cursor
  #           node {
  #             id
  #             localId
  #             name
  #           }
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => nil
  #            },
  #            "edges" => []
  #          } = community_map["members"]

  #   assert cursor

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members(limit: 1, before: #{cursor}) {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #         edges {
  #           cursor
  #           node {
  #             id
  #             localId
  #             name
  #           }
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => cursor
  #            },
  #            "edges" => [
  #              %{
  #                "cursor" => cursor,
  #                "node" => ^actor_map
  #              }
  #            ]
  #          } = community_map["members"]

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members(limit: 1, before: #{cursor}) {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #         edges {
  #           cursor
  #           node {
  #             id
  #             localId
  #             name
  #           }
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => cursor,
  #              "endCursor" => cursor
  #            },
  #            "edges" => [
  #              %{
  #                "cursor" => cursor,
  #                "node" => ^other_actor_map
  #              }
  #            ]
  #          } = community_map["members"]

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members(limit: 1, before: #{cursor}) {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #         edges {
  #           cursor
  #           node {
  #             id
  #             localId
  #             name
  #           }
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")

  #   assert %{
  #            "pageInfo" => %{
  #              "startCursor" => nil,
  #              "endCursor" => cursor
  #            },
  #            "edges" => []
  #          } = community_map["members"]

  #   assert cursor
  # end

  # @tag :user
  # test "works when asking only total count", %{conn: conn, actor: actor} do
  #   community = Factory.community(actor)
  #   comm_local_id = local_id(community)

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members {
  #         totalCount
  #       }
  #     }
  #   }
  #   """

  #   assert community_map =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")
  #            |> Map.fetch!("members")
  #            |> Map.fetch!("totalCount")
  # end

  # @tag :user
  # test "works when asking only page info", %{conn: conn, actor: actor} do
  #   community = Factory.community(actor)
  #   comm_local_id = local_id(community)

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members {
  #         pageInfo {
  #           startCursor
  #           endCursor
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert %{"startCursor" => nil, "endCursor" => nil} =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")
  #            |> Map.fetch!("members")
  #            |> Map.fetch!("pageInfo")
  # end

  # @tag :user
  # test "works when asking only edges", %{conn: conn, actor: actor} do
  #   community = Factory.community(actor)
  #   comm_local_id = local_id(community)

  #   query = """
  #   {
  #     community(localId: #{comm_local_id}) {
  #       members {
  #         edges {
  #           cursor
  #         }
  #       }
  #     }
  #   }
  #   """

  #   assert [%{"cursor" => _}] =
  #            conn
  #            |> post("/api/graphql", %{query: query})
  #            |> json_response(200)
  #            |> Map.fetch!("data")
  #            |> Map.fetch!("community")
  #            |> Map.fetch!("members")
  #            |> Map.fetch!("edges")
  # end
end
