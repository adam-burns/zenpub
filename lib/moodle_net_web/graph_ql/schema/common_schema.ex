defmodule MoodleNetWeb.GraphQL.CommonSchema do
  use Absinthe.Schema.Notation

  interface :node do
    field(:id, non_null(:id))
    field(:local_id, non_null(:integer))
    field(:type, non_null(list_of(non_null(:string))))
    field(:name, :string)
  end

  object :page_info do
    field(:start_cursor, :integer)
    field(:end_cursor, :integer)
  end
end