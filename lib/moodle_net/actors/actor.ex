# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Actors.Actor do
  use MoodleNet.Common.Schema
  import MoodleNet.Common.Changeset, only: [meta_pointer_constraint: 1]
  alias Ecto.Changeset
  alias MoodleNet.Actors.{Actor, ActorFollowerCount, ActorFollowingCount}
  alias MoodleNet.Collections.Collection
  alias MoodleNet.Communities.Community
  alias MoodleNet.Peers.Peer
  alias MoodleNet.Users.User

  # # TODO: match the agreed rules
  # @username_regex ~r([a-zA-Z0-9]+)

  standalone_schema "mn_actor" do
    belongs_to :peer, MoodleNet.Peers.Peer
    # has_one :follower_count, ActorFollowerCount
    # has_one :following_count, ActorFollowingCount
    field :preferred_username, :string
    field :canonical_url, :string
    field :signing_key, :string
    timestamps(inserted_at: :created_at)
  end

  @create_cast ~w(peer_id preferred_username canonical_url signing_key)a
  @create_required ~w(preferred_username)a

  @spec create_changeset(map) :: Changeset.t
  @doc "Creates a changeset for insertion from the given pointer and attrs"
  def create_changeset(attrs) do
    %Actor{}
    |> Changeset.cast(attrs, @create_cast)
    |> Changeset.validate_required(@create_required)
    |> Changeset.validate_format(:preferred_username, @username_regex)
    |> Changeset.unique_constraint(:preferred_username, # with peer
      name: "mn_actor_preferred_username_peer_id_index"
    )
    |> Changeset.unique_constraint(:preferred_username, # without peer (local)
      name: "mn_actor_peer_id_null_index"
    )
    |> meta_pointer_constraint()
  end

  @update_cast ~w(peer_id preferred_username signing_key canonical_url)a

  @spec update_changeset(%Actor{}, map) :: Changeset.t()
  @doc "Creates a changeset for updating the given actor from the given attrs"
  def update_changeset(%Actor{} = actor, attrs) do
    actor
    |> Changeset.cast(attrs, @update_cast)
    |> meta_pointer_constraint()
  end

end
