defmodule MoodleNet.AP.CommunityAspect do
  use ActivityPub.Aspect, persistence: MoodleNet.AP.SQLCommunityAspect

  aspect do
    assoc(:collections, type: "Collection", functional: true, autogenerated: true)
    assoc(:subcommunities, type: "Collection", functional: true, autogenerated: true)
    assoc(:threads, type: "Collection", functional: true, autogenerated: true)
  end

  def autogenerate(:collections, _entity),
    do: ActivityPub.new(%{type: "Collection"})

  def autogenerate(:subcommunities, _entity),
    do: ActivityPub.new(%{type: "Collection"})

  def autogenerate(:threads, _entity),
    do: ActivityPub.new(%{type: "Collection"})
end
