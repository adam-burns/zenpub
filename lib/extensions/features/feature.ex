# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Features.Feature do
  use MoodleNet.Common.Schema
  alias Ecto.Changeset
  alias MoodleNet.Features
  alias __MODULE__
  alias Pointers.Pointer
  alias MoodleNet.Users.User

  @type t :: %__MODULE__{}

  table_schema "mn_feature" do
    belongs_to(:creator, User)
    belongs_to(:context, Pointer)
    field(:canonical_url, :string)
    field(:is_local, :boolean)
    field(:deleted_at, :utc_datetime_usec)
  end

  @create_cast ~w(is_local canonical_url)a
  @create_required ~w(is_local)a

  def create_changeset(%User{id: creator_id}, %{id: context_id}, fields) do
    %__MODULE__{}
    |> Changeset.cast(fields, @create_cast)
    |> Changeset.validate_required(@create_required)
    |> Changeset.change(creator_id: creator_id, context_id: context_id)
  end

  @update_cast ~w(canonical_url)

  def update_changeset(%Feature{} = feat, %{} = attrs) do
    feat
    |> Changeset.cast(attrs, @update_cast)
  end

  ### behaviour callbacks

  def context_module, do: Features

  def queries_module, do: Features.Queries

  def follow_filters, do: []
end
