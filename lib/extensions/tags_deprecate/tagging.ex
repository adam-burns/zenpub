# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Common.Tagging do
  # use CommonsPub.Common.Schema

  # import CommonsPub.Common.Changeset, only: [change_public: 1]
  # alias Ecto.Changeset
  # alias CommonsPub.Users.User
  # alias Pointers.Pointer

  # @type t :: %__MODULE__{}

  # table_schema "mn_tagging" do
  #   belongs_to(:tag, Tag)
  #   belongs_to(:creator, User)
  #   belongs_to(:context, Pointer)
  #   field(:canonical_url, :string)
  #   field(:name, :string)
  #   field(:is_local, :boolean)
  #   field(:is_public, :boolean, virtual: true)
  #   field(:published_at, :utc_datetime_usec)
  #   field(:deleted_at, :utc_datetime_usec)
  #   timestamps(inserted_at: :created_at)
  # end

  # @create_cast ~w(is_public name)a
  # @create_required @create_cast

  # def create_changeset(%User{} = tagger, %Pointer{} = tagged, fields) do
  #   %__MODULE__{}
  #   |> Changeset.cast(fields, @create_cast)
  #   |> Changeset.validate_required(@create_required)
  #   |> Changeset.put_assoc(:tagger, tagger) # BROKEN
  #   |> Changeset.put_assoc(:tagged, tagged)
  #   |> change_public()
  # end

  # @update_cast ~w(is_public name)a
  # @update_required ~w(name)a

  # def update_changeset(%__MODULE__{} = tag, fields) do
  #   tag
  #   |> Changeset.cast(fields, @update_cast)
  #   |> Changeset.validate_required(@update_required)
  #   |> change_public()
  # end
end
