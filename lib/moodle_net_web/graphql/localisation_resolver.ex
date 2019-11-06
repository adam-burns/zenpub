# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.LocalisationResolver do
  @moduledoc "GraphQL Language and Country queries"
  alias MoodleNetWeb.GraphQL
  import MoodleNet.Localisation

  def languages(_, info) do
    GraphQL.response({:ok, Localisation.languages()}, info)
  end

  def countries(_, info) do
    GraphQL.response({:ok, Localisation.countries()}, info)
  end

end
