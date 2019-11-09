# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.InstanceSchema do
  @moduledoc """
  GraphQL activity fields, associations, queries and mutations.
  """
  use Absinthe.Schema.Notation
  alias MoodleNetWeb.GraphQL.InstanceResolver

  object :instance_queries do

    @desc "A logical object for the local instance"
    field :instance, :instance do
      resolve &InstanceResolver.instance/2
    end

  end

  object :instance do

    @desc """
    A list of public activity on the local instance, most recent first
    """
    field :outbox, :generic_activity_page do
      resolve &InstanceResolver/out
    end

  end
end
