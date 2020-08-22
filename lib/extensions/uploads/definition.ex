# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Uploads.Definition do
  alias MoodleNet.Uploads.Storage

  @callback transform(Storage.file_source()) :: {command :: atom, arguments :: [binary]} | :skip

  defmacro __using__(_opts) do
    quote do
      @behaviour MoodleNet.Uploads.Definition
    end
  end
end
