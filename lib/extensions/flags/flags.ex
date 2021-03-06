# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Flags do
  alias CommonsPub.{Activities, Common, Repo}
  alias CommonsPub.Flags.{AlreadyFlaggedError, Flag, NotFlaggableError, Queries}
  alias CommonsPub.Users.User
  alias CommonsPub.Workers.APPublishWorker

  def one(filters), do: Repo.single(Queries.query(Flag, filters))

  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Flag, filters))}

  defp valid_contexts() do
    CommonsPub.Config.get!(__MODULE__)
    |> Keyword.fetch!(:valid_contexts)
  end

  def create(
        %User{} = flagger,
        flagged,
        community \\ nil,
        %{is_local: is_local} = fields
      )
      when is_boolean(is_local) do
    flagged = CommonsPub.Meta.Pointers.maybe_forge!(flagged)
    %Pointers.Table{schema: table} = CommonsPub.Meta.Pointers.table!(flagged)

    if table in valid_contexts() do
      Repo.transact_with(fn ->
        case one(deleted: false, creator: flagger.id, context: flagged.id) do
          {:ok, _} -> {:error, AlreadyFlaggedError.new(flagged.id)}
          _ -> really_create(flagger, flagged, community, fields)
        end
      end)
    else
      {:error, NotFlaggableError.new(flagged.id)}
    end
  end

  defp really_create(flagger, flagged, community, fields) do
    with {:ok, flag} <- insert_flag(flagger, flagged, community, fields),
         {:ok, _activity} <- insert_activity(flagger, flag, "created"),
         :ok <- publish(flagger, flagged, flag, community),
         :ok <- ap_publish("create", flag) do
      {:ok, flag}
    end
  end

  def update_by(%User{}, filters, updates) do
    Repo.update_all(Queries.query(Flag, filters), set: updates)
  end

  def soft_delete(%User{} = user, %Flag{} = flag) do
    Repo.transact_with(fn ->
      with {:ok, flag} <- Common.soft_delete(flag),
           :ok <- chase_delete(user, flag.id),
           :ok <- ap_publish("delete", flag) do
        {:ok, flag}
      end
    end)
  end

  def soft_delete_by(%User{} = user, filters) do
    with {:ok, _} <-
           Repo.transact_with(fn ->
             {_, ids} =
               update_by(user, [{:select, :id}, {:deleted, false} | filters],
                 deleted_at: DateTime.utc_now()
               )

             with :ok <- chase_delete(user, ids) do
               ap_publish("delete", ids)
             end
           end),
         do: :ok
  end

  defp chase_delete(user, ids) do
    Activities.soft_delete_by(user, context: ids)
  end

  # TODO ?
  defp publish(_flagger, _flagged, _flag, _community), do: :ok

  defp ap_publish(verb, flags) when is_list(flags) do
    APPublishWorker.batch_enqueue(verb, flags)
    :ok
  end

  defp ap_publish(verb, %Flag{is_local: true} = flag) do
    APPublishWorker.enqueue(verb, %{"context_id" => flag.id})
    :ok
  end

  defp ap_publish(_, _), do: :ok

  defp insert_activity(flagger, flag, verb) do
    Activities.create(flagger, flag, %{verb: verb, is_local: flag.is_local})
  end

  defp insert_flag(flagger, flagged, community, fields) do
    Repo.insert(Flag.create_changeset(flagger, community, flagged, fields))
  end
end
