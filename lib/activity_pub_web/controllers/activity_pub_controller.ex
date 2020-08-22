# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPubWeb.ActivityPubController do
  @moduledoc """

  TODO The only endpoints implemented so far are for serving an object by ID, so the ActivityPub API can be used to read information from a MoodleNet server.

  Even though store the data in AS format, some changes need to be applied to the entity before serving it in the AP REST response. This is done in `ActivityPubWeb.ActivityPubView`.
  """

  use ActivityPubWeb, :controller

  require Logger

  alias ActivityPub.Actor
  alias ActivityPub.Fetcher
  alias ActivityPub.Object
  alias ActivityPubWeb.ActorView
  alias ActivityPubWeb.Federator
  alias ActivityPubWeb.ObjectView
  alias ActivityPubWeb.RedirectController

  def ap_route_helper(uuid) do
    ap_base_path = System.get_env("AP_BASE_PATH", "/pub")

    MoodleNetWeb.base_url() <> ap_base_path <> "/objects/" <> uuid
  end

  def object(conn, %{"uuid" => uuid}) do
    if get_format(conn) == "html" do
      RedirectController.object(conn, %{"uuid" => uuid})
    else
      with ap_id <- ap_route_helper(uuid),
           %Object{} = object <- Object.get_cached_by_ap_id(ap_id),
           true <- object.public do
        conn
        |> put_resp_content_type("application/activity+json")
        |> put_view(ObjectView)
        |> render("object.json", %{object: object})
      else
        _ ->
          conn
          |> put_status(404)
          |> json(%{error: "not found"})
      end
    end
  end

  def actor(conn, %{"username" => username}) do
    if get_format(conn) == "html" do
      RedirectController.actor(conn, %{"username" => username})
    else
      with {:ok, actor} <- Actor.get_cached_by_username(username) do
        conn
        |> put_resp_content_type("application/activity+json")
        |> put_view(ActorView)
        |> render("actor.json", %{actor: actor})
      else
        _ ->
          conn
          |> put_status(404)
          |> json(%{error: "not found"})
      end
    end
  end

  def following(conn, %{"username" => username, "page" => page}) do
    with {:ok, actor} <- Actor.get_cached_by_username(username) do
      {page, _} = Integer.parse(page)

      conn
      |> put_resp_content_type("application/activity+json")
      |> put_view(ActorView)
      |> render("following.json", %{actor: actor, page: page})
    end
  end

  def following(conn, %{"username" => username}) do
    with {:ok, actor} <- Actor.get_cached_by_username(username) do
      conn
      |> put_resp_content_type("application/activity+json")
      |> put_view(ActorView)
      |> render("following.json", %{actor: actor})
    end
  end

  def followers(conn, %{"username" => username, "page" => page}) do
    with {:ok, actor} <- Actor.get_cached_by_username(username) do
      {page, _} = Integer.parse(page)

      conn
      |> put_resp_content_type("application/activity+json")
      |> put_view(ActorView)
      |> render("followers.json", %{actor: actor, page: page})
    end
  end

  def followers(conn, %{"username" => username}) do
    with {:ok, actor} <- Actor.get_cached_by_username(username) do
      conn
      |> put_resp_content_type("application/activity+json")
      |> put_view(ActorView)
      |> render("followers.json", %{actor: actor})
    end
  end

  def inbox(%{assigns: %{valid_signature: true}} = conn, params) do
    Federator.incoming_ap_doc(params)
    json(conn, "ok")
  end

  # only accept relayed Creates
  def inbox(conn, %{"type" => "Create", "object" => %{"type" => "Group"}} = params) do
    Logger.info(
      "Signature missing or not from author, relayed Create message, fetching object from source"
    )

    Actor.get_or_fetch_by_ap_id(params["object"]["id"])

    json(conn, "ok")
  end

  def inbox(conn, %{"type" => "Create"} = params) do
    Logger.info(
      "Signature missing or not from author, relayed Create message, fetching object from source"
    )

    Fetcher.fetch_object_from_id(params["object"]["id"])

    json(conn, "ok")
  end

  # heck u mastodon
  def inbox(conn, %{"type" => "Delete"}) do
    json(conn, "ok")
  end

  def inbox(conn, params) do
    headers = Enum.into(conn.req_headers, %{})

    if String.contains?(headers["signature"], params["actor"]) do
      Logger.info(
        "Signature validation error for: #{params["actor"]}, make sure you are forwarding the HTTP Host header!"
      )

      Logger.info(inspect(conn.req_headers))
    end

    json(conn, dgettext("errors", "error"))
  end

  def noop(conn, _params) do
    json(conn, "ok")
  end
end
