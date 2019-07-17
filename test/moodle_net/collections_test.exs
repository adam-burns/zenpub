# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.CollectionsTest do
  use MoodleNet.DataCase, async: true

  import ActivityPub.Entity, only: [local_id: 1]
  alias MoodleNet.Collections

  describe "collection flags" do
    test "works" do
      actor = Factory.actor()
      actor_id = local_id(actor)
      comm = Factory.community(actor)
      coll = Factory.collection(actor, comm)
      coll_id = local_id(coll)

      assert [] = Collections.all_flags(actor)

      {:ok, _activity} = Collections.flag(actor, coll, %{reason: "Terrible joke"})

      assert [flag] = Collections.all_flags(actor)
      assert flag.flagged_object_id == coll_id
      assert flag.flagging_object_id == actor_id
      assert flag.reason == "Terrible joke"
      assert flag.open == true
    end
  end

end
