# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
defmodule MoodleNet.Repo.Migrations.ActorNameReservation do
  use Ecto.Migration

  def change do

    create table("actor_name_reservation", primary_key: false) do
      add :id, :bytea, primary_key: true, null: false
      timestamps(type: :utc_datetime_usec, inserted_at: :created_at, updated_at: false)
    end

  end

end
