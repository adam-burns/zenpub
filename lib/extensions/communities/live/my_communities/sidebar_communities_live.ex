defmodule CommonsPub.Web.My.SidebarCommunitiesLive do
  use CommonsPub.Web, :live_component

  import CommonsPub.Utils.Web.CommonHelper

  def update(assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
    }
  end
end
