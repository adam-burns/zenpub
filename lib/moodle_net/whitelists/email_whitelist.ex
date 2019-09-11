# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Whitelist.EmailWhitelist do
  @moduledoc "Whitelists individual email addresses for signup"
  use Ecto.Schema

  @email_regexp ~r/.+\@.+\..+/

  @primary_key false
  schema "mn_whitelist_email" do
    field(:email, :string, primary_key: true)
  end

  def changeset(email) do
    %__MODULE__{}
    |> Changeset.cast(email: email)
    |> Changeset.validate_format(:email, @email_regexp)
  end
end
