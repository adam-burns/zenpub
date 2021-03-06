# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Observation.Process.GraphQL do
  require Logger
  # import ValueFlows.Util, only: [maybe_put: 3]

  alias CommonsPub.{
    # Activities,
    # Communities,
    GraphQL,
    Repo
    # User
  }

  alias CommonsPub.GraphQL.{
    ResolveField,
    # ResolveFields,
    # ResolvePage,
    ResolvePages,
    ResolveRootPage,
    FetchPage
    # FetchPages,
    # CommonResolver
  }

  # alias CommonsPub.Resources.Resource
  # alias CommonsPub.Common.Enums
  # alias CommonsPub.Meta.Pointers
  # alias CommonsPub.Communities.Community
  # alias CommonsPub.Web.GraphQL.CommunitiesResolver

  alias ValueFlows.Observation.Process
  alias ValueFlows.Observation.Process.Processes
  alias ValueFlows.Observation.Process.Queries
  # alias CommonsPub.Web.GraphQL.CommonResolver
  alias CommonsPub.Web.GraphQL.UploadResolver

  # SDL schema import
  #  use Absinthe.Schema.Notation
  # import_sdl path: "lib/value_flows/graphql/schemas/planning.gql"

  ## resolvers

  def simulate(%{id: _id}, _) do
    {:ok, ValueFlows.Simulate.process()}
  end

  def simulate(_, _) do
    {:ok, CommonsPub.Utils.Trendy.some(1..5, &ValueFlows.Simulate.process/0)}
  end

  def process(%{id: id}, info) do
    ResolveField.run(%ResolveField{
      module: __MODULE__,
      fetcher: :fetch_process,
      context: id,
      info: info
    })
  end

  def processes(page_opts, info) do
    ResolveRootPage.run(%ResolveRootPage{
      module: __MODULE__,
      fetcher: :fetch_processes,
      page_opts: page_opts,
      info: info,
      # popularity
      cursor_validators: [&(is_integer(&1) and &1 >= 0), &Ecto.ULID.cast/1]
    })
  end

  def all_processes(_, _) do
    Processes.many([:default])
  end

  def processes_filtered(page_opts, _ \\ nil) do
    IO.inspect(processes_filtered: page_opts)
    processes_filter(page_opts, [])
  end

  # def processes_filtered(page_opts, _) do
  #   IO.inspect(unhandled_filtering: page_opts)
  #   all_processes(page_opts, nil)
  # end

  # TODO: support several filters combined, plus pagination on filtered queries

  defp processes_filter(%{agent: id} = page_opts, filters_acc) do
    processes_filter_next(:agent, [agent_id: id], page_opts, filters_acc)
  end

  defp processes_filter(%{in_scope_of: context_id} = page_opts, filters_acc) do
    processes_filter_next(:in_scope_of, [context_id: context_id], page_opts, filters_acc)
  end

  defp processes_filter(%{tag_ids: tag_ids} = page_opts, filters_acc) do
    processes_filter_next(:tag_ids, [tag_ids: tag_ids], page_opts, filters_acc)
  end

  defp processes_filter(
         _,
         filters_acc
       ) do
    IO.inspect(filters_query: filters_acc)

    # finally, if there's no more known params to acumulate, query with the filters
    Processes.many(filters_acc)
  end

  defp processes_filter_next(param_remove, filter_add, page_opts, filters_acc)
       when is_list(param_remove) and is_list(filter_add) do
    IO.inspect(processes_filter_next: param_remove)
    IO.inspect(processes_filter_add: filter_add)

    processes_filter(Map.drop(page_opts, param_remove), filters_acc ++ filter_add)
  end

  defp processes_filter_next(param_remove, filter_add, page_opts, filters_acc)
       when not is_list(filter_add) do
    processes_filter_next(param_remove, [filter_add], page_opts, filters_acc)
  end

  defp processes_filter_next(param_remove, filter_add, page_opts, filters_acc)
       when not is_list(param_remove) do
    processes_filter_next([param_remove], filter_add, page_opts, filters_acc)
  end

  def track(process, _, _) do
    Processes.track(process)
  end

  def trace(process, _, _) do
    Processes.trace(process)
  end

  def inputs(process, %{action: action_id}, _) when is_binary(action_id) do
    Processes.inputs(process, action_id)
  end

  def inputs(process, _, _) do
    Processes.inputs(process)
  end

  def outputs(process, %{action: action_id}, _) when is_binary(action_id) do
    Processes.outputs(process, action_id)
  end

  def outputs(process, _, _) do
    Processes.outputs(process)
  end

  ## fetchers

  def fetch_process(info, id) do
    Processes.one([
      :default,
      user: GraphQL.current_user(info),
      id: id
      # preload: :tags
    ])
  end

  def creator_processes(%{id: creator}, %{} = page_opts, info) do
    processes_filtered(%{agent: creator})
  end

  def creator_processes_edge(%{creator: creator}, %{} = page_opts, info) do
    ResolvePages.run(%ResolvePages{
      module: __MODULE__,
      fetcher: :fetch_creator_processes_edge,
      context: creator,
      page_opts: page_opts,
      info: info
    })
  end

  def fetch_creator_processes_edge(page_opts, info, ids) do
    list_processes(
      page_opts,
      [
        :default,
        agent_id: ids,
        user: GraphQL.current_user(info)
      ],
      nil,
      nil
    )
  end

  def list_processes(page_opts, base_filters, _data_filters, _cursor_type) do
    FetchPage.run(%FetchPage{
      queries: Queries,
      query: Process,
      # cursor_fn: Processes.cursor(cursor_type),
      page_opts: page_opts,
      base_filters: base_filters
      # data_filters: data_filters
    })
  end

  def fetch_processes(page_opts, info) do
    FetchPage.run(%FetchPage{
      queries: ValueFlows.Observation.Process.Queries,
      query: ValueFlows.Observation.Process,
      # preload: [:provider, :receiver, :tags],
      # cursor_fn: Processes.cursor(:followers),
      page_opts: page_opts,
      base_filters: [
        :default,
        # preload: [:provider, :receiver, :tags],
        user: GraphQL.current_user(info)
      ]
      # data_filters: [page: [desc: [followers: page_opts]]],
    })
  end

  # FIXME: duplication!
  def create_process(%{process: process_attrs}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, uploads} <- UploadResolver.upload(user, process_attrs, info),
           process_attrs = Map.merge(process_attrs, uploads),
           process_attrs = Map.merge(process_attrs, %{is_public: true}),
           {:ok, process} <- Processes.create(user, process_attrs) do
        {:ok, %{process: process}}
      end
    end)
  end

  def update_process(%{process: changes}, info) do
    Repo.transact_with(fn ->
      do_update(changes, info, fn process, changes ->
        Processes.update(process, changes)
      end)
    end)
  end

  defp do_update(%{id: id} = changes, info, update_fn) do
    with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
         {:ok, process} <- process(%{id: id}, info),
         :ok <- ensure_update_permission(user, process),
         {:ok, uploads} <- UploadResolver.upload(user, changes, info),
         changes = Map.merge(changes, uploads),
         {:ok, process} <- update_fn.(process, changes) do
      {:ok, %{process: process}}
    end
  end

  def delete_process(%{id: id}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user_or_not_logged_in(info),
           {:ok, process} <- process(%{id: id}, info),
           :ok <- ensure_update_permission(user, process),
           {:ok, _} <- Processes.soft_delete(process) do
        {:ok, true}
      end
    end)
  end

  def ensure_update_permission(user, process) do
    if user.local_user.is_instance_admin or process.creator_id == user.id do
      :ok
    else
      GraphQL.not_permitted("update")
    end
  end

  # defp validate_agent(pointer) do
  #   if Pointers.table!(pointer).schema in valid_contexts() do
  #     :ok
  #   else
  #     GraphQL.not_permitted()
  #   end
  # end

  # defp valid_contexts() do
  #   [User, Community, Organisation]
  #   # Keyword.fetch!(CommonsPub.Config.get(Threads), :valid_contexts)
  # end
end
