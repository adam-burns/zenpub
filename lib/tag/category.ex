# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Tag.Category do
  use Pointers.Pointable,
    otp_app: :moodle_net,
    source: "category",
    table_id: "TAGSCANBECATEG0RY0RHASHTAG"

  # use MoodleNet.Common.Schema

  import MoodleNet.Common.Changeset, only: [change_public: 1, change_disabled: 1]

  alias Ecto.Changeset
  alias CommonsPub.Tag.Category
  alias MoodleNet.{Repo}

  @type t :: %__MODULE__{}
  @cast ~w(caretaker_id parent_category_id same_as_category_id)a

  pointable_schema do
    # pointable_schema do

    # field(:id, Pointers.ULID, autogenerate: true)

    # eg. Mamals is a parent of Cat
    belongs_to(:parent_category, Category, type: Ecto.ULID)

    # eg. Olive Oil is the same as Huile d'olive
    belongs_to(:same_as_category, Category, type: Ecto.ULID)

    # which community/collection/organisation/etc this category belongs to, if any
    belongs_to(:caretaker, Pointers.Pointer, type: Ecto.ULID)

    # of course, Category is usually a Taggable
    has_one(:taggable, CommonsPub.Tag.Taggable, foreign_key: :id)

    # Optionally, Profile and.or Character mixins
    ## stores common fields like name/description
    has_one(:profile, Profile, foreign_key: :id)
    ## allows it to be follow-able and federate activities
    has_one(:character, Character, foreign_key: :id)

    field(:prefix, :string, virtual: true)
    field(:facet, :string, virtual: true)

    field(:name, :string, virtual: true)
    field(:summary, :string, virtual: true)
    field(:canonical_url, :string, virtual: true)
    field(:preferred_username, :string, virtual: true)
  end

  def create_changeset(attrs) do
    %Category{}
    |> Changeset.change(parent_category_id: parent_category(attrs))
    |> Changeset.change(same_as_category_id: same_as_category(attrs))
    |> Changeset.cast(attrs, @cast)
    |> common_changeset()
  end

  defp parent_category(%{parent_category: parent_category}) when is_binary(parent_category) do
    parent_category
  end

  defp parent_category(%{parent_category: %{id: id}}) when is_binary(id) do
    id
  end

  defp parent_category(_) do
    nil
  end

  defp same_as_category(%{same_as_category: same_as_category}) when is_binary(same_as_category) do
    same_as_category
  end

  defp same_as_category(%{same_as_category: %{id: id}}) when is_binary(id) do
    id
  end

  defp same_as_category(_) do
    nil
  end

  def update_changeset(
        %Category{} = category,
        attrs
      ) do
    category
    |> Changeset.cast(attrs, @cast)
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    # |> Changeset.foreign_key_constraint(:pointer_id, name: :category_pointer_id_fkey)
    # |> change_public()
    # |> change_disabled()
  end

  def context_module, do: CommonsPub.Tag.Category.Categories

  def queries_module, do: CommonsPub.Tag.Category.Queries

  def follow_filters, do: [:default]
end