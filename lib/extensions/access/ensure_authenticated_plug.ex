# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.Web.Plugs.EnsureAuthenticatedPlug do
  @moduledoc """
  Halts the conn if the user is not authenticated
  """
  import Plug.Conn
  import Phoenix.Controller
  alias CommonsPub.Users.User

  def init(options), do: options

  def call(%{assigns: %{current_user: %User{}}} = conn, _), do: conn

  def call(conn, _) do
    case get_format(conn) do
      "json" ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{error: "Invalid credentials."}))
        |> halt()

      "html" ->
        conn
        |> put_flash(:error, "You must be logged in to access to this page")
        |> redirect(to: "/~/login")
        |> halt()
    end
  end
end
