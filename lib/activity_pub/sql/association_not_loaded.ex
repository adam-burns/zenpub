# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.SQL.AssociationNotLoaded do
  @moduledoc """
  When an aspect is not loaded in an entity, all the association fields are set to this struct.
  """
  @enforce_keys [:sql_assoc, :sql_aspect]
  defstruct sql_assoc: nil, sql_aspect: nil, local_id: nil
end
