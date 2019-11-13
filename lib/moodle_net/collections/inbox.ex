# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Collections.Inbox do
  use MoodleNet.Common.Schema

  meta_schema "mn_collection_inbox" do
    belongs_to(:collection, Collection)
    belongs_to(:activity, Activity)
    timestamps(inserted_at: :created_at)
  end
end
