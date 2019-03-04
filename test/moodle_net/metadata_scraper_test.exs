defmodule MoodleNet.MetadataScraperTest do
  use MoodleNet.DataCase, async: true

  alias MoodleNet.MetadataScraper, as: Subject

  @tag :external
  test "works" do
    # FIXME Not a very good test but it is better than nothing
    url = "https://www.youtube.com/watch?v=RYihwKty83A"
    assert {:ok, data} = Subject.fetch(url)
    assert data.author == "Jaime Altozano"
    assert data.embed_code == "https://www.youtube.com/embed/RYihwKty83A"
    assert data.image == "https://i.ytimg.com/vi/RYihwKty83A/maxresdefault.jpg"
    assert data.language == nil
    assert data.resource_type == "video.other"
    assert data.source == "YouTube"
    assert data.summary
    assert data.title == "¿Por qué la música de Harry Potter suena tan MÁGICA?"
  end

  @tag :external
  test "get title" do
    url = "https://en.wikibooks.org/wiki/Spanish"
    assert {:ok, data} = Subject.fetch(url)
    assert data.title == "Spanish - Wikibooks, open books for an open world"
  end

  @tag :external
  test "fix relative image urls" do
    url = "https://graphql.org/learn/schema/#interfaces"
    assert {:ok, data} = Subject.fetch(url)
    assert data.image == "https://graphql.org/img/og_image.png"
  end
end