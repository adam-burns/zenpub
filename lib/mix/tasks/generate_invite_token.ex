defmodule Mix.Tasks.GenerateInviteToken do
  use Mix.Task

  @shortdoc "Generate invite token for user"
  def run([]) do
    Mix.Task.run("app.start")

    with {:ok, token} <- Pleroma.UserInviteToken.create_token() do
      IO.puts("Generated user invite token")

      IO.puts(
        "Url: #{
          Pleroma.Web.Endpoint.url('/register') <> URI.encode_query("invite": token.token)
        }"
      )
    else
      _ ->
        IO.puts("Error creating token")
    end
  end
end
