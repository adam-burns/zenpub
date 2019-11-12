# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Users.LocalUser do
  @moduledoc """
  User model
  """
  use MoodleNet.Common.Schema
  import MoodleNet.Common.Changeset, only: [change_public: 1]
  alias Ecto.Changeset
  alias MoodleNet.Users.{LocalUser, User, EmailConfirmToken}

  standalone_schema "mn_local_user" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :wants_email_digest, :boolean
    field :wants_notifications, :boolean
    field :is_instance_admin, :boolean, default: false
    field :confirmed_at, :utc_datetime_usec
    field :published_at, :utc_datetime_usec
    field :deleted_at, :utc_datetime_usec
    field :disabled_at, :utc_datetime_usec
    has_one :user, User
    has_many :email_confirm_tokens, EmailConfirmToken
    timestamps()
  end

  @email_regexp ~r/.+\@.+\..+/

  @register_cast_attrs ~w(email password wants_email_digest wants_notifications)a
  @register_required_attrs ~w(email password is_public)a

  @doc "Create a changeset for registration"
  def register_changeset(attrs) do
    %LocalUser{}
    |> Changeset.cast(attrs, @register_cast_attrs)
    |> Changeset.change(is_public: true)
    |> Changeset.validate_required(@register_required_attrs)
    |> common_changeset()
  end

  @doc "Create a changeset for confirming an email"
  def confirm_email_changeset(%LocalUser{} = user) do
    Changeset.change(user, confirmed_at: DateTime.utc_now())
  end

  @doc "Create a changeset for unconfirming an email"
  def unconfirm_email_changeset(%LocalUser{} = user) do
    Changeset.change(user, confirmed_at: nil)
  end

  @update_cast_attrs ~w(email password wants_email_digest wants_notifications)a

  @doc "Update the attributes for a user"
  def update_changeset(%LocalUser{} = user, attrs) do
    user
    |> Changeset.cast(attrs, @update_cast_attrs)
    |> common_changeset()
  end
  
  @instance_admin_update_cast_attrs [
    :is_instance_admin, :is_confirmed, :is_public, :is_deleted, :is_disabled,
  ]

  def instance_admin_update_changeset(%LocalUser{} = user, attrs) do
    user
    |> Changeset.cast(attrs, @instance_admin_update_cast_attrs)
    |> common_changeset()
  end
  

  def make_instance_admin_changeset(%User{}=user) do
    user
    |> Changeset.cast(%{}, [])
    |> Changeset.change(is_instance_admin: true)
  end

  def unmake_instance_admin_changeset(%User{}=user) do
    user
    |> Changeset.cast(%{}, [])
    |> Changeset.change(is_instance_admin: false)
  end

  defp common_changeset(changeset) do
    changeset
    |> Changeset.validate_format(:email, @email_regexp)
    |> Changeset.unique_constraint(:email)
    |> Changeset.validate_length(:password, min: 6)
    |> hash_password()
    |> lower_case_email()
    |> change_public()
  end

  # internals

  defp lower_case_email(%Changeset{valid?: false} = ch), do: ch

  defp lower_case_email(%Changeset{} = ch) do
    {_, email} = Changeset.fetch_field(ch, :email)
    Changeset.change(ch, email: String.downcase(email))
  end

  defp hash_password(%Changeset{valid?: true, changes: %{password: pass}} = ch),
    do: Changeset.change(ch, password_hash: Argon2.hash_pwd_salt(pass))

  defp hash_password(changeset), do: changeset

end
