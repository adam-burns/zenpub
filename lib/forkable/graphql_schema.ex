# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.Schema do
  @moduledoc "Root GraphQL Schema"
  use Absinthe.Schema

  alias MoodleNetWeb.GraphQL.{
    AccessSchema,
    ActivitiesSchema,
    AdminSchema,
    BlocksSchema,
    CollectionsSchema,
    CommentsSchema,
    CommonSchema,
    CommunitiesSchema,
    Cursor,
    JSON,
    FeaturesSchema,
    FlagsSchema,
    FollowsSchema,
    InstanceSchema,
    LikesSchema,
    MiscSchema,
    ResourcesSchema,
    ThreadsSchema,
    UsersSchema,
    UploadSchema
  }

  require Logger

  alias MoodleNetWeb.GraphQL.Middleware.CollapseErrors
  alias Absinthe.Middleware.{Async, Batch}

  # @pipeline_modifier OverridePhase

  def plugins, do: [Async, Batch]

  def middleware(middleware, _field, _object) do
    # [{MoodleNetWeb.GraphQL.Middleware.Debug, :start}] ++
    middleware ++ [CollapseErrors]
  end

  import_types(AccessSchema)
  import_types(ActivitiesSchema)
  import_types(AdminSchema)
  import_types(BlocksSchema)
  import_types(CollectionsSchema)
  import_types(CommentsSchema)
  import_types(CommonSchema)
  import_types(CommunitiesSchema)
  import_types(Cursor)
  import_types(FeaturesSchema)
  import_types(FlagsSchema)
  import_types(FollowsSchema)
  import_types(InstanceSchema)
  import_types(JSON)
  import_types(LikesSchema)
  import_types(MiscSchema)
  import_types(ResourcesSchema)
  import_types(ThreadsSchema)
  import_types(UsersSchema)
  import_types(UploadSchema)

  # Extension Modules
  import_types(Profile.GraphQL.Schema)
  import_types(Character.GraphQL.Schema)
  import_types(Organisation.GraphQL.Schema)
  import_types(CommonsPub.Locales.GraphQL.Schema)
  import_types(CommonsPub.Tag.GraphQL.TagSchema)
  import_types(Taxonomy.GraphQL.TaxonomySchema)
  import_types(Measurement.Unit.GraphQL)
  import_types(Geolocation.GraphQL)

  # import_types(ValueFlows.Schema)

  query do
    import_fields(:access_queries)
    import_fields(:activities_queries)
    import_fields(:blocks_queries)
    import_fields(:collections_queries)
    import_fields(:comments_queries)
    import_fields(:common_queries)
    import_fields(:communities_queries)
    import_fields(:features_queries)
    import_fields(:flags_queries)
    import_fields(:follows_queries)
    import_fields(:instance_queries)
    import_fields(:likes_queries)
    import_fields(:resources_queries)
    import_fields(:threads_queries)
    import_fields(:users_queries)

    # Extension Modules
    import_fields(:profile_queries)
    import_fields(:character_queries)
    import_fields(:organisations_queries)
    import_fields(:tag_queries)

    # Taxonomy
    import_fields(:locales_queries)
    import_fields(:taxonomy_queries)

    # ValueFlows
    import_fields(:measurement_query)
    import_fields(:geolocation_query)
    # import_fields(:value_flows_query)
    # import_fields(:value_flows_extra_queries)
  end

  mutation do
    import_fields(:access_mutations)
    import_fields(:admin_mutations)
    import_fields(:blocks_mutations)
    import_fields(:collections_mutations)
    import_fields(:comments_mutations)
    import_fields(:common_mutations)
    import_fields(:communities_mutations)
    import_fields(:features_mutations)
    import_fields(:flags_mutations)
    import_fields(:follows_mutations)
    import_fields(:likes_mutations)
    import_fields(:resources_mutations)
    import_fields(:threads_mutations)
    import_fields(:users_mutations)

    # Extension Modules
    import_fields(:profile_mutations)
    import_fields(:character_mutations)
    import_fields(:organisations_mutations)
    import_fields(:tag_mutations)
    import_fields(:taxonomy_mutations)
    # ValueFlows
    import_fields(:geolocation_mutation)
    import_fields(:measurement_mutation)

    # import_fields(:value_flows_mutation)

    @desc "Fetch metadata from webpage"
    field :fetch_web_metadata, :web_metadata do
      arg(:url, non_null(:string))
      resolve(&MiscSchema.fetch_web_metadata/2)
    end

    # for debugging purposes only:
    # @desc "Fetch an AS2 object from URL"
    # field :fetch_object, type: :fetched_object do
    #   arg :url, non_null(:string)
    #   resolve &MiscSchema.fetch_object/2
    # end
  end

  @doc """
  hydrate SDL schema with resolvers
  """
  def hydrate(%Absinthe.Blueprint{}, _) do
    hydrators = [
      &Geolocation.GraphQL.Hydration.hydrate/0,
      &Measurement.Hydration.hydrate/0
      # &ValueFlows.Hydration.hydrate/0
    ]

    Enum.reduce(hydrators, %{}, fn hydrate_fn, hydrated ->
      hydrate_merge(hydrated, hydrate_fn.())
    end)
  end

  # hydrations fallback
  def hydrate(_node, _ancestors) do
    []
  end

  defp hydrate_merge(a, b) do
    Map.merge(a, b, fn _, a, b -> Map.merge(a, b) end)
  end

  def context_types() do
    schemas = MoodleNet.Meta.TableService.list_pointable_schemas()

    Enum.reduce(schemas, [], fn schema, acc ->
      if Code.ensure_loaded?(schema) and function_exported?(schema, :type, 0) and
           !is_nil(apply(schema, :type, [])) do
        Enum.concat(acc, [apply(schema, :type, [])])
      else
        acc
      end
    end)
  end

  union :any_context do
    description("Any type of known object")

    # TODO: autogenerate

    # types(context_types)

    types([
      :community,
      :collection,
      :resource,
      :comment,
      :flag,
      :follow,
      :like,
      :user,
      :organisation,
      :category,
      :taggable,
      :spatial_thing
      # :intent
    ])

    resolve_type(fn
      %MoodleNet.Users.User{}, _ -> :user
      %MoodleNet.Communities.Community{}, _ -> :community
      %MoodleNet.Collections.Collection{}, _ -> :collection
      %MoodleNet.Resources.Resource{}, _ -> :resource
      %MoodleNet.Threads.Thread{}, _ -> :thread
      %MoodleNet.Threads.Comment{}, _ -> :comment
      %MoodleNet.Follows.Follow{}, _ -> :follow
      %MoodleNet.Likes.Like{}, _ -> :like
      %MoodleNet.Flags.Flag{}, _ -> :flag
      %MoodleNet.Features.Feature{}, _ -> :feature
      %Organisation{}, _ -> :organisation
      %Geolocation{}, _ -> :spatial_thing
      %CommonsPub.Tag.Category{}, _ -> :category
      %CommonsPub.Tag.Taggable{}, _ -> :taggable
      # %ValueFlows.Agent.Agents{}, _ -> :agent
      # %ValueFlows.Agent.People{}, _ -> :person
      # %ValueFlows.Agent.Organizations{}, _ -> :organization
      # %ValueFlows.Planning.Intent{}, _ -> :intent
      o, _ -> IO.inspect(any_context_resolve_unknown_type: o)
    end)
  end
end