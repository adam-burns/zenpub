defmodule MoodleNetWeb.InstanceLive.InstanceMembersPreviewLive do
  use MoodleNetWeb, :live_component

  alias MoodleNetWeb.Helpers.{Profiles}
  import MoodleNetWeb.Helpers.Common

  alias MoodleNetWeb.Component.{
    UserPreviewLive
  }

  alias MoodleNetWeb.GraphQL.{
    UsersResolver
  }

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  defp fetch(socket, assigns) do
    {:ok, users} =
      UsersResolver.users(%{after: assigns.after, limit: 10}, %{
        context: %{current_user: assigns.current_user}
      })

    members = Enum.map(users.edges, &Profiles.prepare(&1, %{icon: true, actor: true}))

    assign(socket,
      members: members,
      has_next_page: users.page_info.has_next_page,
      after: users.page_info.end_cursor,
      before: users.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns)}
  end
end