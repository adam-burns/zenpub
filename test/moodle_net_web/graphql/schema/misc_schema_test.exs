# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNetWeb.GraphQL.MiscTest do
  use MoodleNetWeb.ConnCase, async: true

  @moduletag format: :json

  describe "fetch metadata" do
    @tag :external
    @tag :user
    @url "https://www.youtube.com/watch?v=RYihwKty83A"
    test "fetch metadata", %{conn: conn} do
      # FIXME Not a very good test but it is better than nothing
      query = """
        mutation {
          fetchWebMetadata(url: "#{@url}") {
            title
            summary
            image
            embed_code
            language
            author
            source
            resource_type
          }
        }
      """

      assert metadata =
               conn
               |> Plug.Conn.put_req_header("accept-language", "es")
               |> post("/api/graphql", %{query: query})
               |> json_response(200)
               |> Map.fetch!("data")
               |> Map.fetch!("fetchWebMetadata")

      assert metadata["author"] == "Jaime Altozano"
      assert metadata["embed_code"] == "https://www.youtube.com/embed/RYihwKty83A"
      assert metadata["image"] == "https://i.ytimg.com/vi/RYihwKty83A/maxresdefault.jpg"
      assert metadata["language"] == nil
      assert metadata["resource_type"] == "video.other"
      assert metadata["source"] == "YouTube"
      assert metadata["summary"]
      assert metadata["title"] == "¿Por qué la música de Harry Potter suena tan MÁGICA?"
    end

    test "returns error if not logged in", %{conn: conn} do
      query = """
        mutation {
          fetchWebMetadata(url: "#{@url}") {
            title
            summary
            image
            embed_code
            language
            author
            source
            resource_type
          }
        }
      """

      assert [
               %{
                 "code" => "unauthorized",
                 "message" => "You need to log in first"
               }
             ] =
               conn
               |> post("/api/graphql", %{query: query})
               |> json_response(200)
               |> Map.fetch!("errors")
    end
  end
end