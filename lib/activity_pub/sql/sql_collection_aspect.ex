# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.SQLCollectionAspect do
  @moduledoc """
  `ActivityPub.SQLAspect` for `ActivityPub.CollectionAspect`
  """

  use ActivityPub.SQLAspect,
    aspect: ActivityPub.CollectionAspect,
    persistence_method: :table,
    table_name: "activity_pub_collection_aspects"
end
