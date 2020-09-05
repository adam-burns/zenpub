# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Likes.AlreadyLikedError do
  @enforce_keys [:message, :code, :status]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          message: binary,
          code: binary,
          status: integer
        }

  @doc "Create a new AlreadyLikeError"
  @spec new(type :: binary) :: t
  def new(type) when is_binary(type) do
    %__MODULE__{
      message: "You already like this #{type}.",
      code: "already_liked",
      status: 409
    }
  end
end
