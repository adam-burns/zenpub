defmodule ValueFlows.Proposal.ProposedTo do
  use MoodleNet.Common.Schema

  alias Ecto.Changeset
  alias ValueFlows.Proposal

  @type t :: %__MODULE__{}

  table_schema "vf_proposed_to" do
    belongs_to(:proposed_to, Pointer)
    belongs_to(:proposed, Proposal)
  end

  def changeset(%{id: _} = proposed_to, %Proposal{} = proposed) do
    %__MODULE__{}
    |> Changeset.cast(%{}, [])
    |> Changeset.change(
      proposed_to_id: proposed_to.id,
      proposed_id: proposed.id
    )
  end
end
