defmodule ActivityPub.SQLAssociations.BelongsTo do
  @enforce_keys [:sql_aspect, :aspect, :name]
  defstruct sql_aspect: nil,
    aspect: nil,
    name: nil,
    type: nil,
    autogenerated: nil,
    foreign_key: nil
end
