# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.Test.Orderings do

  defp id(%{id: id}), do: id
  defp updated_at(%{updated_at: upd}), do: upd

  defp follower_count(item) do
    if fc = Map.get(item, :follower_count),
      do: Map.get(fc, :count, 0),
      else: 0
  end

  def stable_sort_by(coll, []), do: coll
  def stable_sort_by(coll, [{fun, sort} | sorts]) do
    stable_sort_by(Enum.sort_by(coll, fun, sort), sorts)
  end

  def order_follower_count(coll) do
    stable_sort_by coll, [
      {&id/1,             :desc},
      {&follower_count/1, :desc}
    ]
  end

end
