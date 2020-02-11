# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.LocalisationSchema do
  @moduledoc "GraphQL languages and countries"

  # use Absinthe.Schema.Notation
  # alias MoodleNetWeb.GraphQL.{CommonResolver, LocalisationResolver}

  # object :localisation_queries do

  #   @desc "Get list of languages we know about"
  #   field :languages, non_null(:languages_edges) do
  #     arg :limit, :integer
  #     arg :before, :string
  #     arg :after, :string
  #     resolve &LocalisationResolver.languages/2
  #   end

  #   field :language, :language do
  #     arg :language_id, non_null(:string)
  #     resolve &LocalisationResolver.language/2
  #   end

  #   field :search_language, non_null(:languages_edges) do
  #     arg :query, non_null(:string)
  #     resolve &LocalisationResolver.search_language/2
  #   end

  #   @desc "Get list of languages we know about"
  #   field :countries, non_null(:countries_edges) do
  #     arg :limit, :integer
  #     arg :before, :string
  #     arg :after, :string
  #     resolve &LocalisationResolver.countries/2
  #   end

  #   field :country, :country do
  #     arg :country_id, non_null(:string)
  #     resolve &LocalisationResolver.country/2
  #   end

  #   field :search_country, :countries_edges do
  #     arg :query, non_null(:string)
  #     resolve &LocalisationResolver.search_country/2
  #   end
  # end

  # object :language do
  #   field :id, :string
  #   field :iso_code2, :string
  #   field :iso_code3, :string
  #   field :english_name, :string
  #   field :local_name, :string
  #   field :created_at, :string do
    #   resolve &CommonResolver.created_at/3
    # end
  #   field :updated_at, :string
  # end

  # object :languages_edges do
  #   field :page_info, non_null(:page_info)
  #   field :edges, list_of(:languages_edge)
  #   field :total_count, non_null(:integer)
  # end

  # object :languages_edge do
  #   field :cursor, non_null(:string)
  #   field :node, :language
  # end

  # object :country do
  #   field :id, :string
  #   field :iso_code2, :string
  #   field :iso_code3, :string
  #   field :english_name, :string
  #   field :local_name, :string
  #   field :created_at, :string do
    #   resolve &CommonResolver.created_at/3
    # end
  #   field :updated_at, :string
  # end

  # object :countries_edges do
  #   field :page_info, non_null(:page_info)
  #   field :edges, list_of(:countries_edge)
  #   field :total_count, non_null(:integer)
  # end

  # object :countries_edge do
  #   field :cursor, non_null(:string)
  #   field :node, :country
  # end

end
