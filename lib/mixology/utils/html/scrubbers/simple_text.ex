defmodule CommonsPub.HTML.Scrubber.SimpleText do
  @moduledoc """
  An HTML scrubbing policy which limits to simple text with only
  paragraphs, breaks and links are allowed through the filter.
  """

  @valid_schemes CommonsPub.Config.get([:uri_schemes, :valid_schemes], ["http", "https"])

  require HtmlSanitizeEx.Scrubber.Meta
  alias HtmlSanitizeEx.Scrubber.Meta

  Meta.strip_comments()

  # links
  Meta.allow_tag_with_uri_attributes(:a, ["href", "data-user", "data-tag"], @valid_schemes)

  Meta.allow_tag_with_this_attribute_values(:a, "class", [
    "hashtag",
    "u-url",
    "mention",
    "u-url mention",
    "mention u-url"
  ])

  Meta.allow_tag_with_this_attribute_values(:a, "rel", [
    "tag",
    "nofollow",
    "noopener",
    "noreferrer"
  ])

  Meta.allow_tag_with_these_attributes(:a, ["name", "title"])

  # paragraphs and linebreaks
  Meta.allow_tag_with_these_attributes(:br, [])
  Meta.allow_tag_with_these_attributes(:p, [])

  # microformats
  Meta.allow_tag_with_this_attribute_values(:span, "class", ["h-card"])
  Meta.allow_tag_with_these_attributes(:span, [])

  # allow inline images for custom emoji
  if CommonsPub.Config.get([:markup, :allow_inline_images]) do
    # restrict img tags to http/https only, because of MediaProxy.
    Meta.allow_tag_with_uri_attributes(:img, ["src"], ["http", "https"])

    Meta.allow_tag_with_these_attributes(:img, [
      "width",
      "height",
      "class",
      "title",
      "alt"
    ])
  end

  Meta.strip_everything_not_covered()
end
