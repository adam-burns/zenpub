# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.SQL.Query do
  @moduledoc """
  Build queries to fetch information from the database
  """

  alias ActivityPub.{SQLEntity, Entity, UrlBuilder}
  import SQLEntity, only: [to_entity: 1]
  import Ecto.Query, only: [from: 2]
  require ActivityPub.Guards, as: APG
  alias MoodleNet.Repo
  alias ActivityPub.SQL.{Common, Paginate}
  alias ActivityPub.SQL.Associations.{ManyToMany, BelongsTo, Collection}

  @doc """
  Start building a new `Query`
  """
  def new() do
    from(entity in SQLEntity, as: :entity)
  end

  def all(%Ecto.Query{} = query) do
    query
    # |> print_query()
    |> Repo.all()
    |> to_entity()
  end

  def count(%Ecto.Query{} = query, opts \\ []) do
    query
    |> Repo.aggregate(:count, :local_id, opts)
  end

  # FIXME this should not be here?
  def delete_all(%Ecto.Query{} = query) do
    query
    |> Repo.delete_all()
  end

  # FIXME this should not be here?
  def update_all(%Ecto.Query{} = query, updates) do
    query
    |> Repo.update_all(updates)
  end

  def one(%Ecto.Query{} = query) do
    query
    # |> print_query()
    |> Repo.one()
    |> to_entity()
  end

  def first(%Ecto.Query{} = query, order_by \\ :local_id) do
    query
    |> Ecto.Query.first(order_by)
    |> one()
  end

  def last(%Ecto.Query{} = query, order_by \\ :local_id) do
    query
    |> Ecto.Query.last(order_by)
    |> one()
  end

  def get_by_local_id(id, opts \\ [])

  def get_by_local_id(id, opts) when is_integer(id) do
    new()
    |> where(local_id: id)
    |> preload_aspect(Keyword.get(opts, :aspect, []))
    |> one()
  end

  def get_by_local_id([], _opts), do: []

  def get_by_local_id(ids, opts) when is_list(ids) do
    from(e in new(),
      where: e.local_id in ^ids
    )
    |> preload_aspect(Keyword.get(opts, :aspect, []))
    |> all()
  end

  def get_by_id(id, opts \\ []) when is_binary(id) do
    case UrlBuilder.get_local_id(id) do
      {:ok, {:page, collection_id, params}} ->
        collection = get_by_local_id(collection_id, opts)
        {:ok, page} = ActivityPub.CollectionPage.new(collection, params)
        page

      {:ok, local_id} ->
        get_by_local_id(local_id, opts)

      :error ->
        new()
        |> where(id: id)
        |> preload_aspect(Keyword.get(opts, :aspect, []))
        |> one()
    end
  end

  def preload(list) when is_list(list) do
    loaded_entities =
      list
      |> Enum.filter(fn
        e when APG.has_status(e, :loaded) -> false
        e when APG.has_status(e, :not_loaded) and APG.has_local_id(e) -> true
        %ActivityPub.SQL.AssociationNotLoaded{local_id: id} when not is_nil(id) -> true
        e -> raise "cannot preload #{inspect(e)}"
      end)
      |> Enum.map(&Common.local_id/1)
      |> get_by_local_id()
      |> Enum.into(%{}, &{Common.local_id(&1), &1})

    Enum.map(list, fn
      e when APG.has_status(e, :loaded) -> e
      e -> loaded_entities[Common.local_id(e)]
    end)
  end

  def preload(entity) do
    [loaded] = preload([entity])
    loaded
  end

  def reload(entity) when APG.is_entity(entity) and APG.has_status(entity, :loaded) do
    new()
    |> where(local_id: Entity.local_id(entity))
    |> preload_aspect(Entity.aspects(entity))
    |> one()
  end

  @doc """
  Paginate queries by creation date using the `local_id` (used for example to paginate the list of users)
  """
  def paginate(%Ecto.Query{} = query, opts \\ %{}) do
    Paginate.by_local_id(query, opts)
  end

  @doc """
  Paginate queries by insertion date in a `Collection` (used for example to paginate the list of followers, which should be sorted by when the `Follow` Activity was created, not when the following actors were created).
  """
  def paginate_collection(%Ecto.Query{} = query, opts \\ %{}) do
    Paginate.by_collection_insert(query, opts)
  end

  def with_type(%Ecto.Query{} = query, type) when is_binary(type) do
    from([entity: entity] in query,
      where: fragment("? @> array[?]", entity.type, ^type)
    )
  end

  def without_type(%Ecto.Query{} = query, type) when is_binary(type) do
    from([entity: entity] in query,
      where: not fragment("? @> array[?]", entity.type, ^type)
    )
  end

  def where(%Ecto.Query{} = query, clauses) do
    from(e in query,
      where: ^clauses
    )
  end

  defp normalize_aspect(:all) do
    ActivityPub.SQLAspect.all()
    |> Enum.filter(&(&1.persistence_method() == :table))
    |> Enum.map(& &1.field_name())
  end


  @doc """
  To load `ActivityPub.Aspect`(s) in case you have an `ActivityPub.Entity` or several `Entities` with some associations and `Aspects` not loaded.

  For a usage example, see `MoodleNet.local_activity_list/1`.

  It is possible to load both aspects and associations at the same time and with deeper associations, see `MoodleNet.update_collection/3` and `MoodleNet.create_resource/3` for examples.

  Note: This function is generated dynamically, checking every `Aspect` and every association using introspection.
  """
  for sql_aspect <- ActivityPub.SQLAspect.all() do
    short_name = sql_aspect.aspect().short_name()
    field_name = sql_aspect.field_name()

    def preload_aspect(%Ecto.Query{} = query, unquote(sql_aspect.aspect())),
      do: preload_aspect(query, unquote(short_name))

    case sql_aspect.persistence_method() do
      m when m in [:fields, :embedded] ->
        defp normalize_aspect(unquote(short_name)), do: nil
        defp normalize_aspect(unquote(field_name)), do: nil
        defp normalize_aspect(unquote(sql_aspect)), do: nil
        defp normalize_aspect(unquote(sql_aspect.aspect())), do: nil
        def preload_aspect(%Ecto.Query{} = query, unquote(short_name)), do: query

      :table ->
        defp normalize_aspect(unquote(short_name)), do: unquote(field_name)
        defp normalize_aspect(unquote(field_name)), do: unquote(field_name)
        defp normalize_aspect(unquote(sql_aspect)), do: unquote(field_name)
        defp normalize_aspect(unquote(sql_aspect.aspect())), do: unquote(field_name)

        # already loaded
        def preload_aspect(
              %Ecto.Query{aliases: %{unquote(field_name) => _}} = query,
              unquote(short_name)
            ),
            do: query

        def preload_aspect(%Ecto.Query{} = query, unquote(short_name)) do
          from([entity: entity] in query,
            left_join: aspect in assoc(entity, unquote(field_name)),
            as: unquote(field_name),
            preload: [{unquote(field_name), aspect}]
          )
        end
    end
  end

  defp normalize_aspect(aspect),
    do: raise(ArgumentError, "Invalid aspect #{inspect(aspect)}")

  def preload_aspect(%Ecto.Query{} = query, aspects) when is_list(aspects),
    do: Enum.reduce(aspects, query, &preload_aspect(&2, &1))

  def preload_aspect(e, _preloads) when APG.is_entity(e) and not APG.has_status(e, :loaded),
    do: preload_error(e)

  def preload_aspect(entity, :all) when APG.is_entity(entity) do
    preload_aspect(entity, Entity.aspects(entity))
  end

  def preload_aspect(entity, preloads) when APG.has_status(entity, :loaded) do
    [entity] = preload_aspect([entity], preloads)
    entity
  end

  def preload_aspect([e | _] = entities, preloads) when APG.is_entity(e) do
    sql_entities = loaded_sql_entities!(entities)
    preloads = normalize_aspects(preloads)

    Repo.preload(sql_entities, preloads)
    |> to_entity()
  end


  defp normalize_aspects(aspect) when not is_list(aspect),
    do: normalize_aspects(List.wrap(aspect))

  defp normalize_aspects(aspects) when is_list(aspects) do
    Enum.reduce(aspects, [], fn aspect, acc ->
      case normalize_aspect(aspect) do
        nil -> acc
        ret -> [ret | acc]
      end
    end)
  end

  defp to_local_ids(entities) do
    Enum.map(entities, fn
      e when APG.is_entity(e) -> Entity.local_id(e)
      int when is_integer(int) -> int
    end)
  end

  @doc """
  `has` and `belongs_to` are generated at compilation time, checking every association defined in the _aspects_.

  A clause function is generated by every association. For a simple example, see `MoodleNet.community_collection_query/1`

  It is important to notice that when the association is a single collection, the query is executed using the collection items, for example, all the communities followed by the given actor in `MoodleNet.joined_communities_query/1`
  """
  def has?(subject, rel, target)
      when APG.is_entity(subject) and APG.has_status(subject, :loaded) and APG.is_entity(target) and
             APG.has_status(target, :loaded)
      when APG.is_entity(subject) and APG.has_status(subject, :loaded) and is_integer(target),
      do: do_has?(subject, rel, target)

  @doc """
  `has` and `belongs_to` are generated at compilation time, checking every association defined in the _aspects_.

  A clause function is generated by every association. For a simple example, see `MoodleNet.community_collection_query/1`

  It is important to notice that when the association is a single collection, the query is executed using the collection items, for example, all the communities followed by the given actor in `MoodleNet.joined_communities_query/1`
  """
  def belongs_to(%Ecto.Query{} = query, collection) when APG.has_type(collection, "Collection") do
    collection_local_id = ActivityPub.local_id(collection)
    from([entity: entity] in query,
      inner_join: rel in "activity_pub_collection_items",
      as: :items,
      on: entity.local_id == rel.target_id,
      where: rel.subject_id == ^collection_local_id
    )
  end

  for sql_aspect <- ActivityPub.SQLAspect.all() do
    Enum.map(sql_aspect.__sql_aspect__(:associations), fn
      %ManyToMany{
        name: name,
        aspect: aspect,
        table_name: table_name,
        join_keys: [subject_key, target_key]
      } ->
        def belongs_to(%Ecto.Query{} = query, unquote(name), local_id) when is_integer(local_id),
          do: belongs_to(query, unquote(name), [local_id])

        def belongs_to(%Ecto.Query{} = query, unquote(name), entity) when APG.is_entity(entity),
          do: belongs_to(query, unquote(name), [Entity.local_id(entity)])

        def belongs_to(%Ecto.Query{} = query, unquote(name), [entity | _] = list)
            when APG.is_entity(entity),
            do: belongs_to(query, unquote(name), to_local_ids(list))

        def has(%Ecto.Query{} = query, unquote(name), local_id) when is_integer(local_id),
          do: has(query, unquote(name), [local_id])

        def has(%Ecto.Query{} = query, unquote(name), entity) when APG.is_entity(entity),
          do: has(query, unquote(name), [Entity.local_id(entity)])

        def has(%Ecto.Query{} = query, unquote(name), [entity | _] = list)
            when APG.is_entity(entity),
            do: has(query, unquote(name), to_local_ids(list))

        def has(%Ecto.Query{} = query, unquote(name), ext_ids) when is_list(ext_ids) do
          from([entity: entity] in query,
            join: rel in fragment(unquote(table_name)),
            as: unquote(name),
            on:
              entity.local_id == field(rel, unquote(subject_key)) and
                field(rel, unquote(target_key)) in ^ext_ids
          )
        end

        defp do_has?(subject, unquote(name), target)
             when APG.has_aspect(subject, unquote(aspect)) do
          target_id = Common.local_id(target)

          subject_id = Common.local_id(subject)

          from(rel in unquote(table_name),
            where:
              ^subject_id == field(rel, unquote(subject_key)) and
                ^target_id == field(rel, unquote(target_key))
          )
          |> Repo.exists?()
        end

        def belongs_to(%Ecto.Query{} = query, unquote(name), ext_ids)
            when is_list(ext_ids) do
          from([entity: entity] in query,
            join: rel in fragment(unquote(table_name)),
            as: unquote(name),
            on:
              entity.local_id == field(rel, unquote(target_key)) and
                field(rel, unquote(subject_key)) in ^ext_ids
          )
        end

      %Collection{
        name: name,
        sql_aspect: sql_aspect,
        aspect: aspect,
        table_name: table_name,
        join_keys: [subject_key, target_key]
      } ->
        def belongs_to(%Ecto.Query{} = query, unquote(name), local_id) when is_integer(local_id),
          do: belongs_to(query, unquote(name), [local_id])

        def belongs_to(%Ecto.Query{} = query, unquote(name), entity) when APG.is_entity(entity) do
          entity = preload_aspect(entity, unquote(sql_aspect))
          local_id = Common.local_id(entity[unquote(name)])
          belongs_to(query, unquote(name), [local_id])
        end

        def belongs_to(%Ecto.Query{} = query, unquote(name), [entity | _] = list)
            when APG.is_entity(entity) do
          local_ids =
            preload_aspect(list, unquote(sql_aspect))
            |> Enum.map(& &1[unquote(name)])
            |> to_local_ids()

          belongs_to(query, unquote(name), local_ids)
        end

        def belongs_to(%Ecto.Query{} = query, unquote(name), ext_ids)
            when is_list(ext_ids) do
          from([entity: entity] in query,
            join: rel in fragment(unquote(table_name)),
            as: unquote(name),
            on:
              entity.local_id == field(rel, unquote(target_key)) and
                field(rel, unquote(subject_key)) in ^ext_ids
          )
        end

        def has(%Ecto.Query{} = query, unquote(name), local_id) when is_integer(local_id),
          do: has(query, unquote(name), [local_id])

        def has(%Ecto.Query{} = query, unquote(name), entity) when APG.is_entity(entity),
          do: has(query, unquote(name), [Entity.local_id(entity)])

        def has(%Ecto.Query{} = query, unquote(name), [entity | _] = list)
            when APG.is_entity(entity),
            do: has(query, unquote(name), to_local_ids(list))

        def has(%Ecto.Query{} = query, unquote(name), ext_ids) when is_list(ext_ids) do
          %{owner_key: owner_key} = unquote(sql_aspect).__schema__(:association, unquote(name))
          # FIXME THIS works perfectly for all aspects except Object!
          query = preload_aspect(query, unquote(aspect))

          from([{unquote(sql_aspect.field_name), entity}] in query,
            join: rel in fragment(unquote(table_name)),
            as: unquote(name),
            on:
              field(entity, ^owner_key) == field(rel, unquote(subject_key)) and
                field(rel, unquote(target_key)) in ^ext_ids
          )
        end

        defp do_has?(subject, unquote(name), target)
             when APG.has_aspect(subject, unquote(aspect)) do
          subject_id = Common.local_id(subject[unquote(name)])
          target_id = Common.local_id(target)

          from(rel in unquote(table_name),
            where:
              ^subject_id == field(rel, unquote(subject_key)) and
                ^target_id == field(rel, unquote(target_key))
          )
          |> Repo.exists?()
        end

      %BelongsTo{} ->
        # TODO has and belongs_to
        []
    end)
  end

  defp normalize_preload_assocs(assoc) when is_atom(assoc), do: normalize_preload_assocs([assoc])

  defp normalize_preload_assocs(assocs) when is_list(assocs) do
    Enum.map(assocs, &normalize_preload_assoc/1)
  end

  defp normalize_preload_assoc({assoc, preload_assoc}) when is_atom(preload_assoc),
    do: normalize_preload_assoc({assoc, [preload_assoc]})

  defp normalize_preload_assoc({assoc, preload_assocs}) when is_list(preload_assocs) do
    normalize_preload_assoc({assoc, {[], preload_assocs}})
  end

  defp normalize_preload_assoc({assoc, {preload_aspects, preload_assocs}})
       when is_list(preload_aspects) and is_list(preload_assocs) do
    normalized_aspects = normalize_aspects(preload_aspects)
    normalized_preloads = normalize_preload_assocs(preload_assocs)

    preloads = normalized_aspects ++ normalized_preloads

    # FIXME assoc can be repetead in normalized_aspects, take a look
    # maybe it is a problem maybe not
    case normalize_preload_assoc(assoc) do
      {aspect, assoc} ->
        {aspect, [{assoc, preloads}]}

      assoc ->
        {assoc, preloads}
    end
  end

  # FIXME normalize assoc should be private
  for sql_aspect <- ActivityPub.SQLAspect.all() do
    case sql_aspect.persistence_method() do
      :table ->
        field_name = sql_aspect.field_name()

        for assoc <- sql_aspect.__sql_aspect__(:associations) do
          defp normalize_preload_assoc(unquote(assoc.name)),
            do: {unquote(field_name), unquote(assoc.name)}
        end

      m when m in [:fields, :embedded] ->
        for assoc <- sql_aspect.__sql_aspect__(:associations) do
          defp normalize_preload_assoc(unquote(assoc.name)), do: unquote(assoc.name)
        end
    end
  end

  @doc """
  To load associations in case you have an `ActivityPub.Entity` or several `Entities`  with some associations and aspects not loaded.

  It is possible to load both aspects and associations at the same time and with deeper associations, see `MoodleNet.update_collection/3` and `MoodleNet.create_resource/3` for examples.
  """

  def preload_assoc([], _preload), do: []

  def preload_assoc(entity, :all) when APG.is_entity(entity) do
    assoc_keys = Map.keys(Entity.assocs(entity))
    preload_assoc(entity, assoc_keys)
  end

  def preload_assoc(entity, preload) when not is_list(preload),
    do: preload_assoc(entity, List.wrap(preload))

  def preload_assoc(e, _preloads) when APG.is_entity(e) and not APG.has_status(e, :loaded),
    do: preload_error(e)

  def preload_assoc(entity, preloads) when APG.has_status(entity, :loaded) do
    sql_entity = Entity.persistence(entity)
    preloads = normalize_preload_assocs(preloads)

    Repo.preload(sql_entity, preloads)
    |> to_entity()
  end

  def preload_assoc([e | _] = entities, preloads) when APG.is_entity(e) do
    sql_entities = loaded_sql_entities!(entities)

    preloads = normalize_preload_assocs(preloads)

    # FIXME check if they are already loaded so we avoid generate
    # the entity again
    Repo.preload(sql_entities, preloads)
    |> to_entity()
  end

  defp loaded_sql_entities!(entities) do
    Enum.map(entities, fn entity ->
      case Entity.persistence(entity) do
        nil -> preload_error(entity)
        persistence -> persistence
      end
    end)
  end

  defp preload_error(e),
    do:
      raise(
        ArgumentError,
        "Invalid status: #{Entity.status(e)}. Only entities with status :loaded can be preloaded"
      )

  def print_query(query) do
    {query_str, args} = Ecto.Adapters.SQL.to_sql(:all, Repo, query)
    IO.puts("#{query_str} <=> #{inspect(args)}")
    query
  end
end
