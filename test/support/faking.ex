# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Test.Faking do
  import ExUnit.Assertions

  alias MoodleNet.{
    Access,
    Activities,
    Actors,
    Communities,
    Collections,
    Flags,
    Follows,
    Features,
    Likes,
    Peers,
    Uploads,
    Users,
    Localisation,
    Resources,
    Threads,
    Threads.Comments,
    Users.User
  }

  import CommonsPub.Utils.Trendy
  import CommonsPub.Utils.Simulation

  def fake_register_email_domain_access!(domain \\ domain())
      when is_binary(domain) do
    {:ok, wl} = Access.create_register_email_domain(domain)
    wl
  end

  def fake_register_email_access!(email \\ email())
      when is_binary(email) do
    {:ok, wl} = Access.create_register_email(email)
    wl
  end

  def fake_language!(overrides \\ %{}) do
    overrides
    |> Map.get(:id, "en")
    |> Localisation.language!()
  end

  def fake_peer!(overrides \\ %{}) when is_map(overrides) do
    {:ok, peer} = Peers.create(peer(overrides))
    peer
  end

  def fake_activity!(user, context, overrides \\ %{}) do
    {:ok, activity} = Activities.create(user, context, activity(overrides))
    assert activity.creator_id == user.id
    activity
  end

  def fake_actor!(overrides \\ %{}) when is_map(overrides) do
    {:ok, actor} = Actors.create(actor(overrides))
    actor
  end

  def fake_user!(overrides \\ %{}, opts \\ []) when is_map(overrides) and is_list(opts) do
    with {:ok, user} <- Users.register(user(overrides), public_registration: true) do
      maybe_confirm_user_email(user, opts)
    end
  end

  def fake_admin!(overrides \\ %{}, opts \\ []) do
    fake_user!(Map.put(overrides, :is_instance_admin, true), opts)
  end

  defp maybe_confirm_user_email(user, opts) do
    if Keyword.get(opts, :confirm_email) do
      {:ok, user} = Users.confirm_email(user)
      user
    else
      user
    end
  end

  def fake_token!(%User{} = user) do
    {:ok, token} = Access.unsafe_put_token(user)
    assert token.user_id == user.id
    token
  end

  def fake_content!(%User{} = user, overrides \\ %{}) do
    {:ok, content} =
      MoodleNet.Uploads.upload(
        MoodleNet.Uploads.ResourceUploader,
        user,
        content_input(overrides),
        %{}
      )

    assert content.uploader_id == user.id
    content
  end

  def fake_community!(user, overrides \\ %{})

  def fake_community!(%User{} = user, %{} = overrides) do
    {:ok, community} = Communities.create(user, community(overrides))
    assert community.creator_id == user.id
    community
  end

  def fake_collection!(user, community, overrides \\ %{})
      when is_map(overrides) and is_nil(community) do
    {:ok, collection} = Collections.create(user, collection(overrides))
    assert collection.creator_id == user.id
    collection
  end

  def fake_collection!(user, community, overrides) when is_map(overrides) do
    {:ok, collection} = Collections.create(user, community, collection(overrides))
    assert collection.creator_id == user.id
    collection
  end

  def fake_resource!(user, collection, overrides \\ %{}) when is_map(overrides) do
    attrs =
      overrides
      |> resource()
      |> Map.put(:content_id, fake_content!(user, overrides).id)

    {:ok, resource} = Resources.create(user, collection, attrs)
    assert resource.creator_id == user.id
    assert resource.collection_id == collection.id
    resource
  end

  def fake_thread!(user, context, overrides \\ %{}) when is_map(overrides) and is_nil(context) do
    {:ok, thread} = Threads.create(user, thread(overrides))
    assert thread.creator_id == user.id
    thread
  end

  def fake_thread!(user, context, overrides) when is_map(overrides) do
    {:ok, thread} = Threads.create(user, context, thread(overrides))
    assert thread.creator_id == user.id
    thread
  end

  def fake_comment!(user, thread, overrides \\ %{}) when is_map(overrides) do
    {:ok, comment} = Comments.create(user, thread, comment(overrides))
    assert comment.creator_id == user.id
    comment
  end

  def fake_reply!(user, thread, comment, overrides \\ %{}) when is_map(overrides) do
    fake = comment(Map.put_new(overrides, :in_reply_to, comment.id))
    {:ok, comment} = Comments.create(user, thread, fake)
    assert comment.creator_id == user.id
    comment
  end

  def some_fake_users!(opts \\ %{}, some_arg) do
    some(some_arg, fn -> fake_user!(opts) end)
  end

  def some_fake_communities!(opts \\ %{}, some_arg, users) do
    flat_pam(users, &some(some_arg, fn -> fake_community!(&1, opts) end))
  end

  def some_fake_resources!(opts \\ %{}, some_arg, users, collections) do
    flat_pam_product_some(users, collections, some_arg, &fake_resource!(&1, &2, opts))
  end

  def some_fake_collections!(opts \\ %{}, some_arg, users, communities) do
    flat_pam_product_some(users, communities, some_arg, &fake_collection!(&1, &2, opts))
  end

  def some_randomer_flags!(opts \\ %{}, some_arg, context) do
    users = some_fake_users!(opts, some_arg)
    pam(users, &flag!(&1, context, opts))
  end

  def some_randomer_follows!(opts \\ %{}, some_arg, context) do
    users = some_fake_users!(opts, some_arg)
    pam(users, &follow!(&1, context, opts))
  end

  def some_randomer_likes!(opts \\ %{}, some_arg, context) do
    users = some(some_arg, &fake_user!/0)
    pam(users, &like!(&1, context, opts))
  end

  def like!(user, context, args \\ %{}) do
    {:ok, like} = Likes.create(user, context, like_input(args))
    assert like.creator_id == user.id
    assert like.context_id == context.id
    like
  end

  def flag!(user, context, args \\ %{}) do
    {:ok, flag} = Flags.create(user, context, flag_input(args))
    assert flag.creator_id == user.id
    assert flag.context_id == context.id
    flag
  end

  def follow!(user, context, args \\ %{}) do
    {:ok, follow} = Follows.create(user, context, follow_input(args))
    assert follow.creator_id == user.id
    assert follow.context_id == context.id
    follow
  end

  def feature!(user, context, args \\ %{}) do
    {:ok, feature} = Features.create(user, context, feature_input(args))
    assert feature.creator_id == user.id
    assert feature.context_id == context.id
    feature
  end
end
