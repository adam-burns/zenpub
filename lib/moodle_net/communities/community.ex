# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Communities.Community do
  use MoodleNet.Common.Schema
  import MoodleNet.Common.Changeset, only: [meta_pointer_constraint: 1, change_public: 1]
  alias Ecto.Changeset
  alias MoodleNet.Actors.Actor
  alias MoodleNet.Common.Flag
  alias MoodleNet.Communities.Community
  alias MoodleNet.Comments.Thread
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Localisation.Language
  alias MoodleNet.Meta
  alias MoodleNet.Meta.Pointer

  meta_schema "mn_community" do
    belongs_to(:creator, Actor)
    belongs_to(:primary_language, Language, type: :string)
    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)
    has_many(:collections, Collection)
    has_many(:flags, Flag)
    timestamps()
  end

  @create_cast ~w(is_public)a
  @create_required @create_cast

  def create_changeset(%Pointer{id: id} = pointer, creator, language, fields) do
    Meta.assert_points_to!(pointer, __MODULE__)

    %Community{id: id}
    |> Changeset.cast(fields, @create_cast)
    |> Changeset.validate_required(@create_required)
    |> Changeset.put_assoc(:creator, creator)
    |> Changeset.put_assoc(:primary_language, language)
    |> change_public()
    |> meta_pointer_constraint()
  end

  @update_cast ~w(is_public)a
  @update_required ~w()a

  def update_changeset(%Community{} = community, fields) do
    community
    |> Changeset.cast(fields, @update_cast)
    |> Changeset.validate_required(@update_required)
    |> change_public()
    |> meta_pointer_constraint()
  end
end
