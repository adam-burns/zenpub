defmodule MoodleNetWeb.MemberLive.MemberDiscussionsLive do
  use MoodleNetWeb, :live_component

  import MoodleNetWeb.Helpers.Common

  alias MoodleNetWeb.Component.{
    DiscussionPreviewLive
  }

  alias MoodleNetWeb.Helpers.{Profiles}

  def mount(socket) do
    {
      :ok,
      socket,
      temporary_assigns: [discussions: [], page: 1, has_next_page: false, after: [], before: []]
    }
  end

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(current_user: assigns.current_user, user: assigns.user)
      |> fetch()
    }
  end

  defp fetch(socket) do
    # IO.inspect(socket.assigns.user)
    {:ok, threads} =
      user =
      MoodleNetWeb.GraphQL.ThreadsResolver.creator_threads_edge(
        %{creator: socket.assigns.user.id},
        %{limit: 3},
        %{context: %{current_user: socket.assigns.current_user}}
      )

    IO.inspect(threads)

    assign(socket,
      threads: threads.edges,
      has_next_page: threads.page_info.has_next_page,
      after: threads.page_info.end_cursor,
      before: threads.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch()}
  end
end
