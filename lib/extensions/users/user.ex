# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Users.User do
  @moduledoc """
  User model
  """
  use CommonsPub.Common.Schema

  import CommonsPub.Common.Changeset,
    only: [change_synced_timestamp: 3, change_public: 1]

  alias Ecto.Changeset
  # alias CommonsPub.Characters.Character
  alias CommonsPub.Feeds.Feed
  alias CommonsPub.Uploads.Content
  alias CommonsPub.Users
  alias CommonsPub.Users.{LocalUser, User}

  # make the schema extensible
  import Flexto, only: [flex_schema: 1]


  table_schema "mn_user" do
    # belongs_to(:actor, Actor)
    has_one(:character, CommonsPub.Characters.Character, references: :id, foreign_key: :id)

    belongs_to(:local_user, LocalUser)
    belongs_to(:inbox_feed, Feed, foreign_key: :inbox_id)
    belongs_to(:outbox_feed, Feed, foreign_key: :outbox_id)
    # belongs_to(:primary_language, Language)
    field(:canonical_url, :string, virtual: true)
    field(:preferred_username, :string, virtual: true)
    field(:name, :string)
    field(:summary, :string)
    field(:location, :string)
    field(:website, :string)
    belongs_to(:icon, Content)
    belongs_to(:image, Content)
    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:is_disabled, :boolean, virtual: true)
    field(:disabled_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)
    field(:stale_error, :string, virtual: true)
    field(:extra_info, :map)
    timestamps()

    flex_schema(:commons_pub) # boom! add extended fields

  end

  @register_required ~w(name)a
  @register_cast ~w(id name summary location website extra_info icon_id image_id is_public)a ++
                   ~w(is_disabled inbox_id outbox_id)a

  @doc "Create a changeset for registration"
  def register_changeset(%{peer_id: peer_id} = attrs) when not is_nil(peer_id) do
    %User{}
    |> Changeset.cast(attrs, @register_cast)
    |> Changeset.validate_required(@register_required)
    |> common_changeset()
  end

  def register_changeset(attrs) do
    %User{}
    |> Changeset.cast(attrs, @register_cast)
    |> Changeset.validate_required(@register_required)
    |> common_changeset()
    |> maybe_local_changeset(true)
  end

  def local_register_changeset(%LocalUser{id: id}, %{} = attrs) do
    register_changeset(attrs)
    |> Changeset.put_change(:local_user_id, id)
  end

  @update_cast [] ++
                 ~w(name summary location website extra_info icon_id image_id is_public)a ++
                 ~w(is_disabled inbox_id outbox_id)a

  @doc "Update the attributes for a user"
  def update_changeset(%User{} = user, attrs) do
    user
    |> Changeset.cast(attrs, @update_cast)
    |> common_changeset()
    |> maybe_local_changeset(is_nil(Map.get(Map.get(user, :character, %{}), :peer_id)))
  end

  defp common_changeset(changeset) do
    changeset
    |> change_synced_timestamp(:is_disabled, :disabled_at)
    |> change_public()
  end

  defp maybe_local_changeset(changeset, true) do
    changeset
    |> Changeset.validate_length(:name, max: 142)
    |> Changeset.validate_length(:summary, max: 500_000)
    |> Changeset.validate_length(:location, max: 255)
    |> Changeset.validate_length(:website, max: 255)
  end

  defp maybe_local_changeset(changeset, false), do: changeset

  ### behaviour callbacks

  def context_module, do: Users

  def queries_module, do: Users.Queries

  def follow_filters, do: [join: :character, preload: :character]
end
