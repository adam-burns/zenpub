# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.AdminResolver do

  def admin(_, info) do
    {:ok, %{}}
  end

  def resolve_flag(%{flag_id: id}, info) do
    {:ok, true}
  end

end
