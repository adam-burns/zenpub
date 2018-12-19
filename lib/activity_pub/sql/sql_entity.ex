defmodule ActivityPub.SQLEntity do
  use Ecto.Schema
  alias Ecto.Multi
  require ActivityPub.Guards, as: APG

  alias ActivityPub.Entity
  alias ActivityPub.{SQLAspect, Context, UrlBuilder, Metadata}
  alias ActivityPub.SQL.{AssociationNotLoaded, FieldNotLoaded}
  alias MoodleNet.Repo

  @primary_key {:local_id, :id, autogenerate: true}
  schema "activity_pub_objects" do
    field(:id, :string)
    field(:"@context", Context)
    field(:type, {:array, :string})
    field(:local, :boolean, default: false)
    field(:extension_fields, :map, default: %{})

    timestamps()

    require ActivityPub.SQLAspect

    for sql_aspect <- SQLAspect.all() do
      ActivityPub.SQLAspect.inject_in_sql_entity_schema(sql_aspect)
    end
  end

  def get_by_local_id(id) when is_integer(id) do
    Repo.get(__MODULE__, id)
    |> to_entity()
  end

  def get_by_id(id) when is_binary(id) do
    case UrlBuilder.get_local_id(id) do
      {:ok, local_id} -> get_by_local_id(local_id)
      :error -> Repo.get_by(__MODULE__, id: id) |> to_entity()
    end
  end

  def reload(entity) when APG.is_entity(entity) and APG.has_status(entity, :loaded) do
    entity |> Entity.local_id() |> get_by_local_id()
  end

  def insert(entity) when APG.is_entity(entity) and APG.has_status(entity, :new) do
    with {:ok, %{entity: sql_entity}} <- insert_new(entity) do
      {:ok, to_entity(sql_entity)}
    end
  end

  defp insert_new(entity) do
    Multi.new()
    |> Multi.insert(:entity, insert_changeset(entity))
    |> Repo.transaction()
  end

  defp insert_changeset(entity) when APG.has_status(entity, :new) do
    ch =
      %__MODULE__{}
      |> Ecto.Changeset.change(from_entity_fields(entity))

    Entity.aspects(entity)
    |> Enum.reduce(ch, fn aspect, ch ->
      insert_changeset_for_aspect(ch, entity, aspect)
    end)
  end

  defp insert_changeset(entity) when APG.has_status(entity, :loaded),
    do: Entity.persistence(entity)

  defp insert_changeset(entity) when APG.is_entity(entity) do
    Ecto.Changeset.change(%__MODULE__{})
    |> Ecto.Changeset.add_error(
      :status,
      "invalid status: #{Entity.status(entity)}. Only status :new and :loaded are valid to insert a new entity."
    )
  end

  defp insert_changeset(nil), do: nil

  defp insert_changeset_for_aspect(ch, entity, aspect) do
    sql_aspect = aspect.persistence()
    field_changes = Entity.fields_for(entity, aspect)
    assoc_changes = Entity.assocs_for(entity, aspect)

    case sql_aspect.persistence_method() do
      :table ->
        assoc_ch =
          struct(sql_aspect)
          |> Ecto.Changeset.change(field_changes)
          |> put_assocs_in_changeset(assoc_changes)

        Ecto.Changeset.put_assoc(ch, aspect.name(), assoc_ch)

      :embedded ->
        assoc_ch = Ecto.Changeset.change(sql_aspect, field_changes)

        Ecto.Changeset.put_embed(ch, aspect.name(), assoc_ch)
        |> put_assocs_in_changeset(assoc_changes)

      :fields ->
        Ecto.Changeset.change(ch, field_changes)
        |> put_assocs_in_changeset(assoc_changes)
    end
  end

  defp put_assocs_in_changeset(changeset, assoc_changes) do
    Enum.reduce(assoc_changes, changeset, fn
      {name, list}, ch when is_list(list) ->
        chs = for data <- list, do: insert_changeset(data)
        Ecto.Changeset.put_assoc(ch, name, chs)

      {name, data}, ch ->
        Ecto.Changeset.put_assoc(ch, name, insert_changeset(data))
    end)
  end

  defp from_entity_fields(entity) when APG.is_entity(entity) do
    entity
    # FIXME add context and local_id
    |> Map.take([:"@context", :id, :type])
    |> Map.put(:local, Entity.local?(entity))
    |> Map.put(:extension_fields, Entity.extension_fields(entity))
  end

  def to_entity(nil), do: nil

  def to_entity(%__MODULE__{} = sql_entity) do
    entity = %{
      __ap__: Metadata.load(sql_entity),
      id: calc_ap_id(sql_entity),
      "@context": Map.fetch!(sql_entity, :"@context"),
      type: sql_entity.type
    }

    aspects = Entity.aspects(entity)

    sql_entity
    |> load_fields(aspects)
    |> Map.merge(load_assocs(sql_entity, aspects))
    |> Map.merge(sql_entity.extension_fields)
    |> Map.merge(entity)
  end

  def to_entity(sql_entities) when is_list(sql_entities),
    do: Enum.map(sql_entities, &to_entity/1)

  defp calc_ap_id(%__MODULE__{local: true, local_id: local_id}), do: UrlBuilder.id(local_id)
  defp calc_ap_id(%__MODULE__{id: id}), do: id

  defp load_fields(%__MODULE__{} = sql_entity, aspects) do
    Enum.reduce(aspects, %{}, fn aspect, acc ->
      case get_sql_data_for_aspect_fields(sql_entity, aspect) do
        %Ecto.Association.NotLoaded{} ->
          aspect.__aspect__(:fields)
          |> Enum.into(acc, &{&1, %FieldNotLoaded{}})

        sql_data ->
          sql_data
          |> Map.take(aspect.__aspect__(:fields))
          |> Map.merge(acc)
      end
    end)
  end

  defp load_assocs(%__MODULE__{} = sql_entity, aspects) do
    Enum.reduce(aspects, %{}, fn aspect, acc ->
      sql_aspect = aspect.persistence()

      case get_sql_data_for_aspect_assocs(sql_entity, aspect) do
        %Ecto.Association.NotLoaded{} ->
          sql_aspect.__sql_aspect__(:associations)
          |> Enum.into(acc, fn sql_assoc ->
            {sql_assoc.name,
             %AssociationNotLoaded{
               sql_assoc: sql_assoc,
               sql_aspect: sql_aspect
             }}
          end)

        sql_data ->
          sql_aspect.__sql_aspect__(:associations)
          |> Enum.reduce(acc, fn sql_assoc, acc ->
            assoc_name = sql_assoc.name

            case Map.fetch!(sql_data, assoc_name) do
              %Ecto.Association.NotLoaded{} ->
                local_id = not_loaded_assoc_local_id(sql_assoc, sql_data)
                Map.put(acc, assoc_name, %AssociationNotLoaded{
                  sql_assoc: sql_assoc,
                  sql_aspect: sql_aspect,
                  local_id: local_id,
                })

              list when is_list(list) ->
                assoc = for sql_entity <- list, do: to_entity(sql_entity)
                Map.put(acc, assoc_name, assoc)

              value ->
                Map.put(acc, assoc_name, to_entity(value))
            end
          end)
      end
    end)

  end

  defp not_loaded_assoc_local_id(%ActivityPub.SQL.Associations.Collection{name: name}, sql_data) do
    key = String.to_atom("#{name}_id")
    Map.get(sql_data, key)
  end

  defp not_loaded_assoc_local_id(_, _), do: nil

  defp get_sql_data_for_aspect_fields(%__MODULE__{} = sql_entity, aspect) do
    aspect.persistence().persistence_method()
    |> case do
      x when x in [:table, :embedded] ->
        Map.fetch!(sql_entity, aspect.name())

      :fields ->
        sql_entity
    end
  end

  defp get_sql_data_for_aspect_assocs(%__MODULE__{} = sql_entity, aspect) do
    aspect.persistence().persistence_method()
    |> case do
      x when x in [:fields, :embedded] ->
        sql_entity

      :table ->
        Map.fetch!(sql_entity, aspect.name())
    end
  end

  # FIXME I think this is not used anymore
  def preload(entity, assocs_or_aspects) when APG.has_status(entity, :loaded) do
    entity
    |> Entity.persistence()
    |> Repo.preload(assocs_or_aspects)
    |> to_entity()
  end
end