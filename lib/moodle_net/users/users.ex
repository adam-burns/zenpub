# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Users do
  # @doc """
  # A Context for dealing with Users.
  # """
  # import Ecto.Query, only: [from: 2]
  # alias MoodleNet.{Actors, Common, Meta, Repo, Whitelists}
  # alias MoodleNet.Actors.{Actor, ActorRevision}
  # alias MoodleNet.Common.NotFoundError

  # alias MoodleNet.Mail.{Email, MailService}

  # alias MoodleNet.Users.{
  #   EmailConfirmToken,
  #   ResetPasswordToken,
  #   TokenAlreadyClaimedError,
  #   TokenExpiredError,
  #   User,
  #   UserFlag
  # }

  # alias Ecto.Changeset

  # @doc "Fetches a user by id"
  # @spec fetch(id :: binary) :: {:ok, %User{}} | {:error, NotFoundError.t()}
  # def fetch(id) when is_binary(id), do: Repo.single(fetch_q(id))

  # def fetch_q(id) do
  #   from u in User,
  #     where: u.id == ^id,
  #     where: is_nil(u.deleted_at)
  # end

  # # TODO: one query
  # def fetch_by_username(username) when is_binary(username) do
  #   Repo.transact_with(fn ->
  #     with {:ok, actor} <- Actors.fetch_by_username(username),
  #          {:ok, user} <- Meta.follow(Meta.forge!(User, actor.alias_id)) do
  #       {:ok, %{user | actor: actor}}
  #     end
  #   end)
  # end

  # def fetch_by_email(email) when is_binary(email) do
  #   Repo.single(fetch_by_email_q(email))
  # end

  # defp fetch_by_email_q(email) do
  #   from u in User,
  #     where: u.email == ^email,
  #     where: is_nil(u.deleted_at)
  # end

  # def fetch_actor(%User{id: id, actor: nil}), do: Actors.fetch_by_alias(id)
  # def fetch_actor(%User{actor: actor}), do: {:ok, actor}

  # def fetch_actor_private(%User{id: id}), do: Actors.fetch_by_alias_private(id)

  # @doc """
  # Registers a user:
  # 1. Splits attrs into actor and user fields
  # 2. Inserts user (because the whitelist check isn't very good at crap emails yet)
  # 3. Checks the whitelist
  # 4. Creates actor, email confirm token

  # This is all controlled by options. An optional keyword list
  # provided to this argument will be prepended to the application
  # config under the path`[:moodle_net, MoodleNet.Users]`. Keys:

  # `:public_registration` - boolean, default false. if false, whitelists will be checked
  # """
  # # @spec register(attrs :: map) :: {:ok, %User{}} | {:error, Changeset.t}
  # # @spec register(attrs :: map, opts :: Keyword.t) :: {:ok, %User{}} | {:error, Changeset.t}
  # def register(%{} = attrs, opts \\ []) do
  #   Repo.transact_with(fn ->
  #     with {:ok, user} <- insert_user(attrs),
  #          :ok <- check_register_whitelist(user.email, opts),
  #          {:ok, actor} <- Actors.create_with_alias(user.id, attrs),
  #          {:ok, token} <- create_email_confirm_token(user) do
  #       user
  #       |> Email.welcome(token)
  #       |> MailService.deliver_now()

  #       {:ok, %{user | email_confirm_tokens: [token], password: nil, actor: actor}}
  #     end
  #   end)
  # end

  # defp should_check_register_whitelist?(opts) do
  #   opts = opts ++ Application.get_env(:moodle_net, __MODULE__, [])
  #   not Keyword.get(opts, :public_registration, false)
  # end

  # defp check_register_whitelist(email, opts) do
  #   if should_check_register_whitelist?(opts),
  #     do: Whitelists.check_register_whitelist(email),
  #     else: :ok
  # end

  # defp insert_user(%{} = attrs) do
  #   Meta.point_to!(User)
  #   |> User.register_changeset(attrs)
  #   |> Repo.insert()
  # end

  # defp create_email_confirm_token(%User{} = user),
  #   do: Repo.insert(EmailConfirmToken.create_changeset(user))

  # @doc "Uses an email confirmation token, returns ok/error tuple"
  # def claim_email_confirm_token(token, now \\ DateTime.utc_now())

  # def claim_email_confirm_token(token, %DateTime{} = now) when is_binary(token) do
  #   Repo.transact_with(fn ->
  #     with {:ok, token} <- Repo.fetch(EmailConfirmToken, token),
  #          :ok <- validate_token(token, :confirmed_at, now),
  #          token = Repo.preload(token, :user),
  #          {:ok, _} <- Repo.update(EmailConfirmToken.claim_changeset(token)) do
  #       confirm_email(token.user)
  #     end
  #   end)
  # end

  # # use the email confirmation mechanism
  # @scope :test
  # @doc """
  # Verify a user's email address, allowing them to access their account.

  # Note: this is for the benefit of the test suite. In normal use you
  # should use the email confirmation mechanism.
  # """
  # def confirm_email(%User{} = user),
  #   do: Repo.update(User.confirm_email_changeset(user))

  # def unconfirm_email(%User{} = user),
  #   do: Repo.update(User.unconfirm_email_changeset(user))

  # def request_password_reset(%User{} = user) do
  #   Repo.transact_with(fn ->
  #     with {:ok, token} <- Repo.insert(ResetPasswordToken.create_changeset(user)) do
  #       user
  #       |> Email.reset_password_request(token)
  #       |> MailService.deliver_now()

  #       {:ok, token}
  #     end
  #   end)
  # end

  # def claim_password_reset(token, password, now \\ DateTime.utc_now())

  # def claim_password_reset(token, password, %DateTime{} = now)
  #     when is_binary(password) do
  #   Repo.transact_with(fn ->
  #     with {:ok, token} <- Repo.fetch(ResetPasswordToken, token),
  #          :ok <- validate_token(token, :reset_at, now),
  #          {:ok, user} <- fetch(token.user_id),
  #          {:ok, token} <- Repo.update(ResetPasswordToken.claim_changeset(token)),
  #          {:ok, _} <- update(user, %{password: password}) do
  #       user
  #       |> Email.password_reset()
  #       |> MailService.deliver_now()

  #       {:ok, token}
  #     end
  #   end)
  # end

  # defp validate_token(token, claim_field, now) do
  #   cond do
  #     not is_nil(Map.fetch!(token, claim_field)) ->
  #       {:error, TokenAlreadyClaimedError.new(token)}

  #     :gt == DateTime.compare(now, token.expires_at) ->
  #       {:error, TokenExpiredError.new(token)}

  #     true ->
  #       :ok
  #   end
  # end

  # def update(%User{} = user, attrs) do
  #   Repo.transact_with(fn ->
  #     with {:ok, actor} <- fetch_actor(user),
  #          {:ok, user} <- Repo.update(User.update_changeset(user, attrs)),
  #          {:ok, actor} <- Actors.update(actor, attrs) do
  #       {:ok, %User{user | actor: actor}}
  #     end
  #   end)
  # end

  # def soft_delete(%User{} = user) do
  #   Repo.transact_with fn ->
  #     with {:ok, user} <- Repo.update(User.soft_delete_changeset(user)),
  #          {:ok, actor} <- fetch_actor(user),
  #          {:ok, actor} <- Actors.soft_delete(actor) do
  #       {:ok, %User{user | actor: actor}}
  #     end
  #   end
  # end

  # def make_instance_admin(%User{}=user) do
  #   Repo.update(User.make_instance_admin_changeset(user))
  # end

  # def unmake_instance_admin(%User{}=user) do
  #   Repo.update(User.unmake_instance_admin_changeset(user))
  # end

  # def preload_actor(%User{} = user, opts),
  #   do: Repo.preload(user, :actor, opts)

  # defp extra_relation(%User{id: id}) when is_integer(id), do: :user

  # defp preload_extra(%User{} = user, opts \\ []),
  #   do: Repo.preload(user, extra_relation(user), opts)
end
