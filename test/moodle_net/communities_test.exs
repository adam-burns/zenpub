# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.CommunitiesTest do
  use MoodleNet.DataCase, async: true

  import ActivityPub.Entity, only: [local_id: 1]
  alias MoodleNet.Communities

  describe "community flags" do
    test "works" do
      actor = Factory.actor()
      actor_id = local_id(actor)
      comm = Factory.community(actor)
      comm_id = local_id(comm)

      assert [] = Communities.all_flags(actor)

      {:ok, _activity} = Communities.flag(actor, comm, %{reason: "Terrible joke"})

      assert [flag] = Communities.all_flags(actor)
      assert flag.flagged_object_id == comm_id
      assert flag.flagging_object_id == actor_id
      assert flag.reason == "Terrible joke"
      assert flag.open == true
    end
  end

end
