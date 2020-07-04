defmodule MoodleNetWeb.DiscussionLive do
  use MoodleNetWeb, :live_view
  import MoodleNetWeb.Helpers.Common
  alias MoodleNetWeb.GraphQL.{ThreadsResolver, CommentsResolver}
  alias MoodleNetWeb.Helpers.{Account, Discussion}
  alias MoodleNetWeb.Component.CommentPreviewLive

  def mount(%{"id" => id} = params, session, socket) do
    socket = init_assigns(params, session, socket)
    current_user = socket.assigns.current_user

    {:ok, thread} =
      ThreadsResolver.thread(%{thread_id: id}, %{
        context: %{current_user: current_user}
      })

    thread = Discussion.prepare_thread(thread)
    IO.inspect(thread, label: "THREAD")

    {:ok, comments} =
      CommentsResolver.comments_edge(thread, %{}, %{
        context: %{current_user: current_user}
      })

    comments_edges = Enum.map(comments.edges, &Discussion.prepare_comment/1)
    IO.inspect(comments_edges, label: "COMMENTS")
    [head | tail] = comments_edges

    {:ok,
     assign(socket,
       current_user: current_user,
       thread: thread,
       main_comment: head,
       comments: tail
     )}
  end
end
