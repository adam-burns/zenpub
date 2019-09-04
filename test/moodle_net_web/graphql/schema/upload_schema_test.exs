# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNetWeb.GraphQL.UploadSchemaTest do
  use MoodleNetWeb.ConnCase, async: true

  import ActivityPub.Entity, only: [local_id: 1]
  @moduletag format: :json

  # TODO: delete upload directory

  def upload_query(actor, query_name, file) do
    local_id = local_id(actor)
    query = """
    mutation {
      #{query_name}(image: \"image\", localId: #{local_id})
    }
    """

    %{
      "query" => query,
      "variables" => %{"image" => "file"},
      "image" => file
    }
  end

  def assert_valid_url(url) do
    uri = URI.parse(url)
    assert uri.scheme
    assert uri.host
    assert uri.path
  end

  setup_all do
    on_exit(fn ->
      File.rm_rf!(MoodleNetWeb.Uploader.storage_dir())
    end)
  end

  describe "image" do
    @tag :user
    test "upload an image for an existing object", %{conn: conn, actor: actor} do
      file = %Plug.Upload{
        path: "test/fixtures/images/150.png",
        filename: "150.png",
        content_type: "image/png"
      }
      query = upload_query(actor, "uploadImage", file)

      assert resp =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api/graphql", query)
        |> json_response(200)

      refute Map.has_key?(resp, "errors")
      assert %{"data" => %{"uploadImage" => url}} = resp
      assert url =~ "#{local_id(actor)}/#{file.filename}"
      assert_valid_url url

      fetch_query = """
      query {
        user(localId: #{local_id(actor)}) {
          image
        }
      }
      """
      assert resp =
        conn
        |> post("/api/graphql", %{query: fetch_query})
        |> json_response(200)
      assert get_in(resp, ["data", "user", "image"]) == url
    end

    @tag :user
    test "fails with an invalid file extension", %{conn: conn, actor: actor} do
      file = %Plug.Upload{
        path: "test/fixtures/not-a-virus.exe",
        filename: "not-a-virus.exe",
        content_type: "application/executable"
      }
      query = upload_query(actor, "uploadImage", file)

      assert resp =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api/graphql", query)
        |> json_response(200)

      assert %{"errors" => [%{"message" => "invalid_file"}]} = resp
      assert %{"data" => %{"uploadImage" => nil}} = resp
    end

    @tag :user
    test "fails with an missing file", %{conn: conn, actor: actor} do
      file = %Plug.Upload{
        path: "missing.png",
        filename: "missing.png",
        content_type: "image/png"
      }
      query = upload_query(actor, "uploadImage", file)

      assert resp =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api/graphql", query)
        |> json_response(200)

      assert %{"errors" => [%{"message" => "not_found"}]} = resp
      assert %{"data" => %{"uploadImage" => nil}} = resp
    end
  end

  describe "icon" do
    @tag :user
    test "upload an icon for an existing object", %{conn: conn, actor: actor} do
      file = %Plug.Upload{
        path: "test/fixtures/images/150.png",
        filename: "150.png",
        content_type: "image/png"
      }
      query = upload_query(actor, "uploadIcon", file)

      assert resp =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api/graphql", query)
        |> json_response(200)

      refute Map.has_key?(resp, "errors")
      assert %{"data" => %{"uploadIcon" => url}} = resp
      assert url =~ "#{local_id(actor)}/full_#{file.filename}"
      assert_valid_url url

      fetch_query = """
      query {
        user(localId: #{local_id(actor)}) {
          icon {
            url
            mediaType
            width
            height
            preview {
              url
              mediaType
              width
              height
            }
          }
        }
      }
      """
      assert resp =
        conn
        |> post("/api/graphql", %{query: fetch_query})
        |> json_response(200)

      assert %{
        "url" => ^url,
        "mediaType" => "image/png",
        "width" => 150,
        "height" => 150
      } = get_in(resp, ["data", "user", "icon"])

      preview = get_in(resp, ["data", "user", "icon", "preview"])
      assert preview["url"] =~ "#{local_id(actor)}/thumbnail_#{file.filename}"
      assert_valid_url preview["url"]
      assert %{
        "mediaType" => "image/png",
        "width" => 300,
        "height" => 300
      } = preview
    end

    @tag :user
    test "fails with an invalid file extension", %{conn: conn, actor: actor} do
      file = %Plug.Upload{
        path: "test/fixtures/not-a-virus.exe",
        filename: "not-a-virus.exe",
        content_type: "application/executable"
      }
      query = upload_query(actor, "uploadIcon", file)

      assert resp =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api/graphql", query)
        |> json_response(200)

      assert %{"errors" => [%{"message" => "invalid_file"}]} = resp
      assert %{"data" => %{"uploadIcon" => nil}} = resp
    end

    @tag :user
    test "fails with an missing file", %{conn: conn, actor: actor} do
      file = %Plug.Upload{
        path: "missing.png",
        filename: "missing.png",
        content_type: "image/png"
      }
      query = upload_query(actor, "uploadIcon", file)

      assert resp =
        conn
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/api/graphql", query)
        |> json_response(200)

      assert %{"errors" => [%{"message" => "not_found"}]} = resp
      assert %{"data" => %{"uploadIcon" => nil}} = resp
    end
  end
end
