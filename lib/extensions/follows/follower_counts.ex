# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Follows.FollowerCounts do
  alias MoodleNet.Repo
  alias MoodleNet.Follows.{FollowerCount, FollowerCountsQueries}
  alias MoodleNet.GraphQL.Fields

  def one(filters), do: Repo.single(FollowerCountsQueries.query(FollowerCount, filters))

  def many(filters \\ []) do
    {:ok, Repo.all(FollowerCountsQueries.query(FollowerCount, filters))}
  end

  def fields(group_fn, filters \\ [])
      when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    Fields.new(fields, group_fn)
  end
end
