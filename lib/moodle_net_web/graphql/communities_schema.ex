# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.CommunitiesSchema do
  @moduledoc """
  GraphQL community fields, associations, queries and mutations.
  """
  use Absinthe.Schema.Notation
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Comments.Comment
  alias MoodleNet.Resources.Resource
  alias MoodleNetWeb.GraphQL.CommunitiesResolver

  object :communities_queries do

    @desc "Get list of communities, most followed first"
    field :communities, :community_page do
      arg :limit, :integer
      arg :before, :string
      arg :after, :string
      resolve &CommunitiesResolver.list/2
    end

    @desc "Get a community"
    field :community, :community do
      arg :community_id, non_null(:string)
      resolve &CommunitiesResolver.fetch/2
    end
  end

  object :communities_mutations do

    @desc "Create a community"
    field :create_community, type: :community do
      arg :community, non_null(:community_input)
      resolve &CommunitiesResolver.create/2
    end

    @desc "Update a community"
    field :update_community, type: :community do
      arg :community_id, non_null(:string)
      arg :community, non_null(:community_input)
      resolve &CommunitiesResolver.update/2
    end

  end

  object :community do
    @desc "An instance-local UUID identifying the user"
    field :id, :string
    @desc "A url for the community, may be to a remote instance"
    field :canonical_url, :string
    @desc "An instance-unique identifier shared with users and collections"
    field :preferred_username, :string

    @desc "A name field"
    field :name, :string
    @desc "Possibly biographical information"
    field :summary, :string
    @desc "An avatar url"
    field :icon, :string
    @desc "A header background image url"
    field :image, :string

    @desc "When the community was created"
    field :created_at, :string
    @desc "When the community was last updated"
    field :updated_at, :string
    @desc """
    When the community or a resource or collection in it was last
    updated or a thread or a comment was created or updated
    """
    field :last_activity, :string

    @desc "Whether the community is local to the instance"
    field :is_local, :boolean
    @desc "Whether the community has a public profile"
    field :is_public, :boolean
    @desc "Whether an instance admin has disabled the community"
    field :is_disabled, :boolean

    @desc "The current user's follow of the community, if any"
    field :my_follow, :follow do
      resolve &CommonResolver.my_follow/3
    end
 
    @desc "The primary language the community speaks"
    field :primary_language, :language do
      resolve &CommonResolver.primary_language/3
    end

    @desc "The user who created the community"
    field :creator, :user do
      resolve &CommunitiesResolver.creator/3
    end

    @desc "The communities a user has joined, most recently joined first"
    field :collections, :community_collections_connection do
      arg :limit, :integer
      arg :before, :string
      arg :after, :string
      resolve &CommunitiesResolver.collections/3
    end

    @desc """
    Threads started on the community, in most recently updated
    order. Does not include threads started on collections or
    resources
    """
    field :threads, :community_threads_connection do
      arg :limit, :integer
      arg :before, :string
      arg :after, :string
      resolve &CommunitiesResolver.threads/3
    end

    @desc "Users following the community, most recently followed first"
    field :followers, :community_followers_connection do
      arg :limit, :integer
      arg :before, :string
      arg :after, :string
      resolve &CommonResolver.followers/3
    end

    @desc "Activities for community moderators. Not available to plebs."
    field :inbox, :community_activities_connection do
      arg :limit, :integer
      arg :before, :string
      arg :after, :string
      resolve &CommunitiesResolver.inbox/3
    end

    @desc "Activities in the community, most recently created first"
    field :outbox, :community_activities_connection do
      arg :limit, :integer
      arg :before, :string
      arg :after, :string
      resolve &CommunitiesResolver.outbox/3
    end

  end

  object :community_page do
    field :page_info, non_null(:page_info)
    field :nodes, list_of(:community)
    field :total_count, non_null(:integer)
  end

  object :community_collections_connection do
    field :page_info, non_null(:page_info)
    field :edges, list_of(:community_collections_edge)
    field :total_count, non_null(:integer)
  end

  object :community_collections_edge do
    field :cursor, non_null(:string)
    field :node, :collection
  end

  object :community_threads_connection do
    field :page_info, non_null(:page_info)
    field :edges, list_of(:community_threads_edge)
    field :total_count, non_null(:integer)
  end

  object :community_threads_edge do
    field :cursor, non_null(:string)
    field :node, :thread
  end

  object :community_followers_connection do
    field :page_info, non_null(:page_info)
    field :edges, list_of(:community_followers_edge)
    field :total_count, non_null(:integer)
  end

  object :community_followers_edge do
    field :cursor, non_null(:string)
    field :node, :follow
  end

  object :community_activities_connection do
    field :page_info, non_null(:page_info)
    field :edges, list_of(:community_activities_edge)
    field :total_count, non_null(:integer)
  end

  object :community_activities_edge do
    field :cursor, non_null(:string)
    field :node, :activity
  end

  input_object :community_input do
    field :primary_language_id, non_null(:string)
    field :name, non_null(:string)
    field :summary, non_null(:string)
    field :preferred_username, non_null(:string)
    field :icon, :string
    field :image, :string
  end

end
