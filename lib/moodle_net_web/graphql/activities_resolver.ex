# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.ActivitiesResolver do
  alias MoodleNet.Fake
  alias MoodleNet.Activities.Activity
  
  def context(%Activity{}=parent, _, info) do
    {:ok, GraphQL.response(Fake.activity_context(), info)}
  end

end
