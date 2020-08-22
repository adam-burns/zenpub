# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Collections.CollectionFollowerCount do
  use MoodleNet.Common.Schema
  alias MoodleNet.Collections.Collection

  view_schema "mn_collection_follower_count" do
    belongs_to(:collection, Collection, primary_key: true)
    field(:count, :integer)
  end
end
