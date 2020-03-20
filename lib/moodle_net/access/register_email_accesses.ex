# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Access.RegisterEmailAccesses do

  alias MoodleNet.Repo
  alias MoodleNet.Access.{RegisterEmailAccess, RegisterEmailAccessesQueries}
  alias MoodleNet.Batching.EdgesPage

  def one(filters) do
    Repo.single(RegisterEmailAccessesQueries.query(RegisterEmailAccess, filters))
  end

  def many(filters \\ []) do
    {:ok, Repo.all(RegisterEmailAccessesQueries.query(RegisterEmailAccess, filters))}
  end

  def edges_page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  when is_function(cursor_fn, 1) do
    {data_q, count_q} = RegisterEmailAccessesQueries.queries(RegisterEmailAccess, base_filters, data_filters, count_filters)
    with {:ok, [data, count]} <- Repo.transact_many(all: data_q, count: count_q) do
      {:ok, EdgesPage.new(data, count, cursor_fn, page_opts)}
    end
  end

  def create(email) do
    Repo.insert(RegisterEmailAccess.create_changeset(%{email: email}))
  end
  
end
