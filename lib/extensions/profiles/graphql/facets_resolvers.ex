# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Profiles.GraphQL.FacetsResolvers do
  @moduledoc "These resolver functions are to be called by other modules that use profile, for fields or foreign keys that are part of the profile table rather than that module's table."

  # alias CommonsPub.Profiles.Profile
  alias Pointers

  def creator_edge(%{profile: %{creator_id: id}}, _, info),
    do: CommonsPub.Web.GraphQL.UsersResolver.creator_edge(%{creator_id: id}, nil, info)

  def is_public_edge(%{profile: profile}, _, _), do: {:ok, not is_nil(profile.published_at)}
  def is_disabled_edge(%{profile: profile}, _, _), do: {:ok, not is_nil(profile.disabled_at)}
  def is_hidden_edge(%{profile: profile}, _, _), do: {:ok, not is_nil(profile.hidden_at)}
  def is_deleted_edge(%{profile: profile}, _, _), do: {:ok, not is_nil(profile.deleted_at)}

  def my_like_edge(%{profile_id: id}, page_opts, info),
    do: CommonsPub.Web.GraphQL.LikesResolver.my_like_edge(%{id: id}, page_opts, info)

  def likers_edge(%{profile_id: id}, page_opts, info),
    do: CommonsPub.Web.GraphQL.LikesResolver.likers_edge(%{id: id}, page_opts, info)

  def liker_count_edge(%{profile_id: id}, page_opts, info),
    do: CommonsPub.Web.GraphQL.LikesResolver.liker_count_edge(%{id: id}, page_opts, info)

  def my_flag_edge(%{profile_id: id}, page_opts, info),
    do: CommonsPub.Web.GraphQL.FlagsResolver.my_flag_edge(%{id: id}, page_opts, info)

  def flags_edge(%{profile_id: id}, page_opts, info),
    do: CommonsPub.Web.GraphQL.FlagsResolver.flags_edge(%{id: id}, page_opts, info)

  def icon_content_edge(%{profile: %{icon_id: id}}, _, info),
    do: CommonsPub.Web.GraphQL.UploadResolver.icon_content_edge(%{icon_id: id}, nil, info)

  def image_content_edge(%{profile: %{image_id: id}}, _, info),
    do: CommonsPub.Web.GraphQL.UploadResolver.image_content_edge(%{image_id: id}, nil, info)
end
