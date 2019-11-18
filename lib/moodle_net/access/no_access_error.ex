# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Access.NoAccessError do
  @enforce_keys [:message, :code, :status]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    message: binary,
    code: binary,
    status: integer,
  }

  @doc "Create a new NoAccessError"
  @spec new() :: t

  def new() do
    %__MODULE__{
      message: "Registration is currently by invitation only",
      code: "no_access",
      status: 403,
    }
  end
end
