# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Access.UserDisabledError do
  @enforce_keys []
  defstruct @enforce_keys

  @type t :: %__MODULE__{}

  @spec new() :: t
  @doc "Create a new UserDisabledError"
  def new(), do: %__MODULE__{}
  
end
