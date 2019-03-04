defmodule ActivityPub.ObjectAspect do
  use ActivityPub.Aspect, persistence: ActivityPub.SQLObjectAspect

  alias ActivityPub.{LanguageValueType}

  aspect do
    assoc(:attachment)
    assoc(:attributed_to)
    assoc(:attributed_to_inv, inv: :attributed_to)
    field(:content, LanguageValueType, default: %{})
    assoc(:context)
    assoc(:context_inv, inv: :context)
    field(:name, LanguageValueType, default: %{})
    field(:end_time, :utc_datetime)
    assoc(:generator)
    assoc(:icon)
    assoc(:image)
    # FIXME
    assoc(:in_reply_to)
    assoc(:location)
    assoc(:preview)
    field(:published, :utc_datetime)
    # FIXME
    assoc(:replies, inv: :in_reply_to)
    field(:start_time, :utc_datetime)
    field(:summary, LanguageValueType, default: %{})
    assoc(:tag)
    field(:updated, :utc_datetime)
    # FIXME url is a relation
    # field(:url, EntityType, default: [])
    field(:url, :string, functional: false)

    assoc(:to)
    assoc(:bto)
    assoc(:cc)
    assoc(:bcc)
    assoc(:audience)

    field(:media_type, :string)
    field(:duration, :string)

    # FIXME this doesn't exist in ActivityPub
    # adding because it is easier
    assoc(:likers)
    field(:likers_count, :integer, autogenerated: true)

    field(:followed, :boolean, virtual: true)
    field(:liked, :boolean, virtual: true)

    field(:cursor, :integer, virtual: true)
  end
end