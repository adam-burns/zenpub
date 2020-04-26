# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Application do
  @moduledoc """
  MoodleNet Application
  """
  use Application
  alias MoodleNet.Repo
  alias MoodleNet.Localisation.{CountryService, LanguageService}
  alias MoodleNet.Meta.TableService
  alias MoodleNetWeb.Endpoint
  import Supervisor.Spec, only: [supervisor: 2, worker: 2]

  @name Mix.Project.config()[:name]
  @version Mix.Project.config()[:version]
  @repository Mix.Project.config()[:source_url]

  def name, do: @name
  def version, do: @version
  def named_version, do: @name <> " " <> @version
  def repository, do: @repository

  def start(_type, _args) do

    MoodleNet.ReleaseTasks.startup_migrations() # start repos, run migrations, stop repos

    {:ok, _} = Logger.add_backend(Sentry.LoggerBackend)
    :ok = Oban.Telemetry.attach_default_logger(:debug)
    :ok = :telemetry.attach("oban-logger", [:oban, :failure], &MoodleNet.Workers.ObanLogger.handle_event/4, nil)

    # TODO: better supervision tree. LS, CS and TS only need repo on
    # startup, never need restarting, but they should require repo to
    # start, endpoint should attempt to serve users without the repo
    # and does not need it to start up
    children = [
      supervisor(Repo, []),
      worker(TableService, []),
      supervisor(Endpoint, []),
      {Oban, Application.get_env(:moodle_net, Oban)},
      %{
        id: :cachex_actor,
        start:
          {Cachex, :start_link,
           [
             :ap_actor_cache,
             [
               default_ttl: 25_000,
               ttl_interval: 1000,
               limit: 2500
             ]
           ]}
      },
      %{
        id: :cachex_object,
        start:
          {Cachex, :start_link,
           [
             :ap_object_cache,
             [
               default_ttl: 25_000,
               ttl_interval: 1000,
               limit: 2500
             ]
           ]}
      }
    ]

    opts = [strategy: :one_for_one, name: MoodleNet.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
