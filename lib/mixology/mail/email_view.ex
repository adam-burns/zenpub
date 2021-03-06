# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.Web.EmailView do
  @moduledoc """
  Email view
  """
  use CommonsPub.Web, :view

  def app_name(), do: CommonsPub.Config.get(:app_name)
end
