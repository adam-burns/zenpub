# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.Adapter do
  @moduledoc """
  Contract for ActivityPub module adapters
  """

  alias ActivityPub.Actor
  alias ActivityPub.Object
  alias MoodleNet.Config

  @adapter Config.get!(ActivityPub.Adapter)[:adapter]

  @doc """
  Fetch an actor given its preferred username
  """
  @callback get_actor_by_username(String.t()) :: {:ok, any()} | {:error, any()}
  defdelegate get_actor_by_username(username), to: @adapter

  @callback get_actor_by_id(String.t()) :: {:ok, any()} | {:error, any()}
  defdelegate get_actor_by_id(username), to: @adapter

  @callback maybe_create_remote_actor(Actor.t()) :: :ok
  defdelegate maybe_create_remote_actor(actor), to: @adapter

  @callback update_local_actor(Actor.t(), Map.t()) :: {:ok, any()} | {:error, any()}
  defdelegate update_local_actor(actor, params), to: @adapter

  @doc """
  Passes data to be handled by the host application
  """
  @callback handle_activity(Object.t()) :: :ok | {:ok, any()} | {:error, any()}
  defdelegate handle_activity(activity), to: @adapter

  # FIXME: implicity returning `:ok` here means we don't know if the worker fails which isn't great
  def maybe_handle_activity(%Object{local: false} = activity) do
    handle_activity(activity)
    :ok
  end

  def maybe_handle_activity(_), do: :ok
end
