# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.Mail.EmailTest do
  use MoodleNet.DataCase, async: true

  alias MoodleNet.Mail.Email
  import MoodleNet.Test.Faking
  alias CommonsPub.Utils.Simulation

  setup do
    {:ok, %{user: fake_user!()}}
  end

  test "welcome/2", %{user: user} do
    token = "this_is_the_token"
    email = Email.welcome(user, %{id: token})

    assert email.to == user.local_user.email
    assert email.html_body =~ token
    assert email.text_body =~ token
  end

  test "reset_password_request/2", %{user: user} do
    token = "this_is_the_token"
    email = Email.reset_password_request(user, %{id: token})

    assert email.to == user.local_user.email
    assert email.html_body =~ token
    assert email.text_body =~ token
  end

  test "password_reset/1", %{user: user} do
    email = Email.password_reset(user)
    assert email.to == user.local_user.email
  end

  test "invite/1" do
    address = Simulation.email()
    email = Email.invite(address)
    assert email.to == address
  end
end
