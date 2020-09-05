# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.MetadataScraper do
  @moduledoc """
  Given a url, it downloads the html metadata
  """
  @furlex_media_types ~w(text/html application/xml+xhtml)
  @request_opts [follow_redirect: true]

  def fetch(url) when is_binary(url) do
    url = CommonsPub.Utils.File.ensure_valid_url(url)
    IO.inspect(scrape_url: url)

    try do
      if url != "" do
        file_info_res = TwinkleStar.from_uri(url, @request_opts)

        with {:ok, file_info} <- file_info_res do
          data =
            case unfurl(url, file_info) do
              {:ok, data} -> data
              {:error, _} -> %{}
            end

          {:ok, Map.put(data, :media_type, file_info.media_type)}
        end
      else
        {:error, :invalid_or_missing_url}
      end
    rescue
      e ->
        IO.inspect(scraping_error: e)
        {:error, :scraper_malfunction}
    end
  end

  defp unfurl(url, %{media_type: media_type}) do
    # HACK: furlex breaks if passed anything unsupported
    if media_type in @furlex_media_types do
      with {:ok, data} <- Furlex.unfurl(url, @request_opts) do
        {:ok, format_data(data, url, media_type)}
      end
    else
      {:error, :furlex_unsupported_format}
    end
  end

  defp format_data(data, url, media_type) do
    %{
      url: url,
      title: title(data),
      summary: summary(data),
      image: image(data, url),
      embed_code: embed_code(data),
      language: language(data),
      author: author(data),
      source: source(data),
      embed_type: embed_type(data),
      mime_type: media_type
    }
  end

  defp title(data) do
    (get(data, :facebook, "title") || get(data, :twitter, "title") || get(data, :oembed, "title") ||
       get(data, :html, "title"))
    |> only_first()
  end

  defp summary(data) do
    (get(data, :facebook, "description") || get(data, :twitter, "description") ||
       get(data, :html, "description"))
    |> only_first()
  end

  defp image(data, original_url) do
    (get(data, :facebook, "image") || get(data, :twitter, "image") ||
       get(data, :other, "thumbnail_url"))
    |> only_first()
    |> CommonsPub.Utils.File.fix_relative_url(original_url)
  end

  defp embed_code(data) do
    (get(data, :facebook, "video:url") || get(data, :facebook, "audio:url") ||
       get(data, :twitter, "player") || get(data, :oembed, "html") || get(data, :oembed, "url"))
    |> only_first()
  end

  defp language(data) do
    (get(data, :facebook, "locale") || get(data, :other, "language"))
    |> only_first()
  end

  defp author(data) do
    (get(data, :facebook, "article:author") || get(data, :twitter, "creator") ||
       get(data, :oembed, "author_name") || get(data, :other, "author"))
    |> only_first()
  end

  defp source(data) do
    (get(data, :facebook, "site_name") || get(data, :oembed, "provider_name"))
    |> only_first()
  end

  defp embed_type(data) do
    (get(data, :facebook, "type") || get(data, :oembed, "type"))
    |> only_first()
  end

  defp get(data, :facebook, label),
    do: Map.get(data.facebook, "og:#{label}")

  defp get(data, :twitter, label),
    do: Map.get(data.twitter, "twitter:#{label}")

  defp get(%{oembed: nil}, :oembed, _label), do: nil

  defp get(%{oembed: oembed}, :oembed, label),
    do: Map.get(oembed, label)

  defp get(data, :html, label),
    do: Map.get(data.html, label)

  defp get(data, :other, label),
    do: Map.get(data.other, label)

  defp only_first([head | _]), do: head
  defp only_first(arg), do: arg
end
