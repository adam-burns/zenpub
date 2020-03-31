# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.Test.Automaton do
  @moduledoc "Pagination testing"
  import ExUnit.Assertions
  import MoodleNet.Test.Trendy
  import MoodleNetWeb.Test.GraphQLAssertions
  import MoodleNetWeb.Test.GraphQLFields
  import MoodleNetWeb.Test.ConnHelpers
  import Zest

  def root_page_test(
    %{query: query,
      connection: conn,
      return_key: key,
      default_limit: default_limit,
      total_count: total,
      data: data,
      assert_fn: assert_fn,
      cursor_fn: cursor_fn,
    }=opts
  ) do
    default_vars = Map.get(opts, :vars, %{})
    limit = Map.get(opts, :limit, :limit)
    aft = Map.get(opts, :after, :after)
    bef = Map.get(opts, :before, :before)
    assert is_map(default_vars)
    # test the first page with default limit
    page1 = query_page(query, conn, key, default_vars, 10, total, false, true, cursor_fn)
    each(data, page1.edges, assert_fn)
    # test the first page with explicit limit
    vars = Map.merge(default_vars, %{limit => 11})
    page_1 = query_page(query, conn, key, vars, 11, total, false, true, cursor_fn)
    each(data, page_1.edges, assert_fn)
    # test the second page with explicit limit
    vars = Map.merge(default_vars, %{limit => 9, aft => page_1.end_cursor})
    page2 = query_page(query, conn, key, vars, 9, total, true, true, cursor_fn)
    drop_each(data, page2.edges, 11, assert_fn)
    # test the third page with explicit limit
    vars = Map.merge(default_vars, %{limit => 7, aft => page2.end_cursor})
    page3 = query_page(query, conn, key, vars, 7, total, true, false, cursor_fn)
    drop_each(data, page3.edges, 20, assert_fn)
    # test the second page without explicit limit
    vars = Map.merge(default_vars, %{aft => page1.end_cursor})
    page_2 = query_page(query, conn, key, vars, 10, total, true, true, cursor_fn)
    drop_each(data, page_2.edges, 10, assert_fn)
    # test the third page without explicit limit
    vars = Map.merge(default_vars, %{aft => page_2.end_cursor})
    page_3 = query_page(query, conn, key, vars, 7, total, true, false, cursor_fn)
    drop_each(data, page_3.edges, 20, assert_fn)
  end

  def child_page_test(
    %{query: query,
      connection: conn,
      parent_key: parent_key,
      child_key: child_key,
      count_key: count_key,
      default_limit: default_limit,
      total_count: total,
      data: data,
      parent_assert_fn: parent_assert_fn,
      child_assert_fn: child_assert_fn,
      cursor_fn: cursor_fn,
      after: aft,
      before: bef,
      limit: limit,
    }=opts
  ) do
    default_vars = Map.get(opts, :vars, %{})
    assert is_map(default_vars)
    # test the first page with default limit
    parent = parent_assert_fn.(grumble_post_key(query, conn, parent_key, default_vars))
    # page1 = query_page(query, conn, parent_key, default_vars, 10, total, false, true, cursor_fn)
    # each(data, page1.edges, assert_fn)
    # # test the first page with explicit limit
    # vars = Map.merge(default_vars, %{limit => 11})
    # page_1 = query_page(query, conn, key, vars, 11, total, false, true, cursor_fn)
    # each(data, page_1.edges, assert_fn)
    # # test the second page with explicit limit
    # vars = Map.merge(default_vars, %{limit => 9, aft => page_1.end_cursor})
    # page2 = query_page(query, conn, key, vars, 9, total, true, true, cursor_fn)
    # drop_each(data, page2.edges, 11, assert_fn)
    # # test the third page with explicit limit
    # vars = Map.merge(default_vars, %{limit => 7, aft => page2.end_cursor})
    # page3 = query_page(query, conn, key, vars, 7, total, true, false, cursor_fn)
    # drop_each(data, page3.edges, 20, assert_fn)
    # # test the second page without explicit limit
    # vars = Map.merge(default_vars, %{aft => page1.end_cursor})
    # page_2 = query_page(query, conn, key, vars, 10, total, true, true, cursor_fn)
    # drop_each(data, page_2.edges, 10, assert_fn)
    # # test the third page without explicit limit
    # vars = Map.merge(default_vars, %{aft => page_2.end_cursor})
    # page_3 = query_page(query, conn, key, vars, 7, total, true, false, cursor_fn)
    # drop_each(data, page_3.edges, 20, assert_fn)
  end

  defp query_page(query, conn, key, vars, count, total, prev, next, cursor_fn) do
    grumble_post_key(query, conn, key, vars)
    |> assert_page(count, total, prev, next, cursor_fn)
  end



end
