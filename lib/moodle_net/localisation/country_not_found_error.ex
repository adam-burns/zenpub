# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Localisation.CountryNotFoundError do
  @enforce_keys [:id]
  defstruct @enforce_keys

  @type t :: %__MODULE__{ id: term }

  @spec new(term) :: t
  @doc "Create a new CountryNotFoundError with the given iso code"
  def new(id), do: %__MODULE__{id: id}
end
