defmodule MoodleNetWeb.Component.UnknownPreviewLive do
  use Phoenix.LiveComponent

  import MoodleNetWeb.Helpers.Common

  def render(assigns) do
    IO.inspect(unknown_preview: assigns.object)
    link = e(content_url(assigns.object), e(assigns.object, :canonical_url, "#no-link"))
    IO.inspect(link: link)

    ~L"""
    <div class="story__preview">
      <div class="preview__info">
        <h2><a href="<%=link%>"><%= e(@object, :name, "") %></a></h2>
        <p><%= e(@object, :summary, "") %></p>
        <div class="preview__meta">
          <div class="meta__item">
            <i class="feather-message-square"></i>
            5
          </div>
          <div class="meta__item">
            <i class="feather-star"></i>
            13
          </div>
        </div>
      </div>
      <div class="preview__icon" style="background-image: url('<%= icon(@object) %>')"></div>

    </div>
    """
  end
end
