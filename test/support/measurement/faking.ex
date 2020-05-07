# # Based on code from MoodleNet
# # Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# # SPDX-License-Identifier: AGPL-3.0-only
defmodule Measurement.Test.Faking do
  @moduledoc false

  alias MoodleNet.Test.Fake
  import MoodleNetWeb.Test.GraphQLAssertions
  import MoodleNetWeb.Test.GraphQLFields
  import MoodleNet.Test.Trendy

  import Grumble

  alias Measurement.Unit
  alias Measurement.Unit.Units

  @doc "A unit"
  def unit_name(), do: Faker.Util.pick(["kilo", "liter"])
  def unit_symbol(), do: Faker.Util.pick(["kg", "m"])


  ### Start fake data functions

  ## Unit

  def unit(base \\ %{}) do
    base
    |> Map.put_new_lazy(:label, &Fake.name/0)
    |> Map.put_new_lazy(:symbol, &Fake.name/0)
    |> Map.put_new_lazy(:is_public, &Fake.truth/0)
    |> Map.put_new_lazy(:is_disabled, &Fake.falsehood/0)
    |> Map.put_new_lazy(:is_featured, &Fake.falsehood/0)
    |> Map.merge(Fake.actor(base))
  end

  def fake_unit!(user, community, overrides \\ %{}) when is_map(overrides) do
    {:ok, unit} = Units.create(user, community, unit(overrides))
    unit
  end

  ### Graphql fields

  def unit_subquery(options \\ []) do
    gen_subquery(:id, :unit, &unit_fields/1, options)
  end

  def unit_query(options \\ []) do
    gen_query(:id, &unit_subquery/1, options)
  end

  def unit_fields(extra \\ []) do
    extra ++ ~w(id label symbol __typename)a
  end


  def units_query(options \\ []) do
    params = [
      units_after: list_type(:cursor),
      units_before: list_type(:cursor),
      units_limit: :int,
    ] ++ Keyword.get(options, :params, [])
    gen_query(&units_subquery/1, [ {:params, params} | options ])
  end

  def units_subquery(options \\ []) do
    args = [
      after: var(:units_after),
      before: var(:units_before),
      limit: var(:units_limit),
    ]
    page_subquery :units,
      &[ :follower_count | unit_fields(&1)],
      [ {:args, args} | options ]
  end


  ### Unit assertion

  def assert_unit(unit) do
    assert_object unit, :assert_unit,
      [id: &assert_ulid/1,
       label: &assert_binary/1,
       symbol: &assert_binary/1,

       typename: assert_eq("Unit"),
      ]
  end

  def assert_unit(%Unit{}=unit, %{id: _}=unit2) do
    assert_units_eq(unit, unit2)
  end

  def assert_unit(%Unit{}=unit, %{}=unit2) do
    assert_units_eq(unit, assert_unit(unit2))
  end


  def assert_units_eq(%Unit{}=unit, %{}=unit2) do
    assert_maps_eq unit, unit2, :assert_unit,
      [:id, :label, :symbol]
    unit2
  end

  def some_fake_units!(opts \\ %{}, some_arg, users, communities) do
    flat_pam_product_some(users, communities, some_arg, &fake_unit!(&1, &2, opts))
  end
end
