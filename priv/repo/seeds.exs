# Generate some fake data and put it in the DB for testing/development purposes

import CommonsPub.Test.Faking
alias CommonsPub.Utils.Simulation

admin =
  %{
    email: "root@localhost.dev",
    preferred_username: System.get_env("SEEDS_USER", "root"),
    password: System.get_env("SEEDS_PW", "123456"),
    name: System.get_env("SEEDS_USER", "root"),
    is_instance_admin: true
  }
  |> fake_user!(confirm_email: true)

# create some users
users = for _ <- 1..2, do: fake_user!()
random_user = fn -> Faker.Util.pick(users) end

# start some communities
communities = for _ <- 1..2, do: fake_community!(random_user.())
subcommunities = for _ <- 1..2, do: fake_community!(random_user.(), Faker.Util.pick(communities))
maybe_random_community = fn -> Simulation.maybe_one_of(communities ++ subcommunities) end

# create fake collections
collections = for _ <- 1..4, do: fake_collection!(random_user.(), maybe_random_community.())
subcollections = for _ <- 1..2, do: fake_collection!(random_user.(), Faker.Util.pick(collections))
maybe_random_collection = fn -> Simulation.maybe_one_of(collections ++ subcollections) end

# start fake threads
for _ <- 1..3 do
  user = random_user.()
  thread = fake_thread!(user, maybe_random_community.())
  comment = fake_comment!(user, thread)
  # reply to it
  reply = fake_comment!(random_user.(), thread, %{in_reply_to_id: comment.id})
  subreply = fake_comment!(random_user.(), thread, %{in_reply_to_id: reply.id})
  subreply2 = fake_comment!(random_user.(), thread, %{in_reply_to_id: subreply.id})
end

# more fake threads
for _ <- 1..2 do
  user = random_user.()
  thread = fake_thread!(user, maybe_random_collection.())
  comment = fake_comment!(user, thread)
end

# post some links/resources
for _ <- 1..2, do: fake_resource!(random_user.(), maybe_random_community.())
for _ <- 1..2, do: fake_resource!(random_user.(), maybe_random_collection.())

# define some tags/categories
if(Code.ensure_loaded?(CommonsPub.Tag.Simulate)) do
  for _ <- 1..2 do
    category = CommonsPub.Tag.Simulate.fake_category!(random_user.())
    _subcategory = CommonsPub.Tag.Simulate.fake_category!(random_user.(), category)
  end
end

# define some geolocations
if(Code.ensure_loaded?(Geolocation.Simulate)) do
  for _ <- 1..2,
      do: Geolocation.Simulate.fake_geolocation!(random_user.(), maybe_random_community.())

  for _ <- 1..2,
      do: Geolocation.Simulate.fake_geolocation!(random_user.(), maybe_random_collection.())
end

# define some units
if(Code.ensure_loaded?(Measurement.Simulate)) do
  for _ <- 1..2 do
    unit1 = Measurement.Simulate.fake_unit!(random_user.(), maybe_random_community.())
    unit2 = Measurement.Simulate.fake_unit!(random_user.(), maybe_random_collection.())

    if(Code.ensure_loaded?(ValueFlows.Simulate)) do
      for _ <- 1..2,
          do:
            ValueFlows.Simulate.fake_intent!(
              random_user.(),
              Faker.Util.pick([unit1, unit2]),
              maybe_random_community.()
            )
    end
  end
end

# conduct some fake economic activities
if(Code.ensure_loaded?(ValueFlows.Simulate)) do
  for _ <- 1..2 do
    user = random_user.()

    _process_spec =
      ValueFlows.Simulate.fake_process_specification!(user, maybe_random_community.())

    intent = ValueFlows.Simulate.fake_intent!(user, nil, maybe_random_community.())
    proposal = ValueFlows.Simulate.fake_proposal!(user, maybe_random_community.())
    ValueFlows.Simulate.fake_proposed_to!(random_user.(), proposal)
    ValueFlows.Simulate.fake_proposed_intent!(proposal, intent)
  end
end
