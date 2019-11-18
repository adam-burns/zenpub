# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# Contains code from Pleroma <https://pleroma.social/> and CommonsPub <https://commonspub.org/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNet.Mail.Email do
  @moduledoc """
  Email Bamboo module
  """
  import MoodleNetWeb.Gettext
  use Bamboo.Phoenix, view: MoodleNetWeb.EmailView
  alias MoodleNet.Users

  def welcome(user, token) do
    url = email_confirmation_url(user.id, token.id)
    base_email(user)
    |> subject(gettext("Welcome to MoodleNet"))
    |> render(:welcome, user: user, url: url)
  end

  def reset_password_request(user, token) do
    url = reset_password_url(token.id)
    base_email(user)
    |> subject(gettext("Did you forget your MoodleNet password?"))
    |> render(:reset_password_request, user: user, url: url)
  end

  def password_reset(user) do
    base_email(user)
    |> subject(gettext("Your MoodleNet password has been reset"))
    |> render(:password_reset)
  end

  defp base_email(user) do
    {:ok, local_user} = Users.fetch_local_user(user)
    new_email()
    |> to(local_user.email)
    # FIXME domain configuration
    |> from("no-reply@moodle.net")
    |> put_layout({MoodleNetWeb.LayoutView, :email})
  end

  defp email_confirmation_url(_id, token),
    do: frontend_url("confirm-email/#{token}")

  defp reset_password_url(token), do: frontend_url("reset/#{token}")

  # Note that the base url is expected to end without a slash (/)
  defp frontend_url(path) do
    Application.fetch_env!(:moodle_net, :frontend_base_url) <> "/" <> path
  end
end