# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Feeds do

  alias MoodleNet.Feeds.{Feed, Queries}
  alias MoodleNet.Repo
  
  def instance_outbox_id(), do: "10CA11NSTANCE00TB0XFEED1D0"
  def instance_inbox_id(),  do: "10CA11NSTANCE1NB0XFEED1D00"

  @doc "Retrieves a single feed by arbitrary filters."
  def one(filters), do: Repo.single(Queries.query(Feed, filters))

  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Feed, filters))}

  def create(), do: Repo.insert(Feed.create_changeset())

  def update_by(filters, updates), do: Repo.update_all(Queries.query(Feed, filters), updates)

end
