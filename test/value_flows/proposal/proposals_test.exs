# SPDX-License-Identifier: AGPL-3.0-only#
defmodule ValueFlows.Proposal.ProposalsTest do
  use CommonsPub.Web.ConnCase, async: true

  import CommonsPub.Utils.Trendy, only: [some: 2]
  import CommonsPub.Test.Faking

  import Geolocation.Simulate

  import Measurement.Simulate
  import Measurement.Test.Faking

  import ValueFlows.Simulate
  import ValueFlows.Test.Faking

  alias ValueFlows.Proposal.Proposals

  describe "one" do
    test "fetches an existing proposal by ID" do
      user = fake_user!()
      proposal = fake_proposal!(user)

      assert {:ok, fetched} = Proposals.one(id: proposal.id)
      assert_proposal_full(proposal, fetched)
      assert {:ok, fetched} = Proposals.one(user: user)
      assert_proposal_full(proposal, fetched)
      # TODO
      # assert {:ok, fetched} = Intents.one(context: comm)
    end
  end

  describe "create" do
    test "can create a proposal" do
      user = fake_user!()
      attrs = proposal()

      assert {:ok, proposal} = Proposals.create(user, attrs)
      assert_proposal_full(proposal)
      assert proposal.unit_based == attrs[:unit_based]
    end

    test "can create a proposal with a scope" do
      user = fake_user!()
      parent = fake_user!()

      assert {:ok, proposal} = Proposals.create(user, parent, proposal())
      assert_proposal_full(proposal)
      assert proposal.context_id == parent.id
    end

    test "can create a proposal with an eligible location" do
      user = fake_user!()
      location = fake_geolocation!(user)

      attrs = proposal(%{eligible_location_id: location.id})
      assert {:ok, proposal} = Proposals.create(user, attrs)
      assert proposal.eligible_location_id == location.id
    end
  end

  describe "update" do
    test "can update an existing proposal" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      new_attrs = proposal()

      assert {:ok, updated} = Proposals.update(proposal, new_attrs)
      assert_proposal_full(updated)
      assert updated.updated_at != proposal.updated_at
      assert updated.unit_based == new_attrs[:unit_based]
    end

    test "can update an existing proposal with a new context" do
      user = fake_user!()
      context = fake_community!(user)
      proposal = fake_proposal!(user, context)

      new_context = fake_community!(user)
      assert {:ok, updated} = Proposals.update(proposal, new_context, proposal())
      assert_proposal_full(updated)
      assert updated.updated_at != proposal.updated_at
      assert updated.context_id == new_context.id
    end
  end

  describe "one_proposed_intent" do
    test "fetches an existing proposed intent" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      intent = fake_intent!(user)

      proposed_intent = fake_proposed_intent!(proposal, intent)
      assert {:ok, fetched} = Proposals.one_proposed_intent(id: proposed_intent.id)
      assert_proposed_intent(fetched)
      assert fetched.id == proposed_intent.id

      assert {:ok, fetched} = Proposals.one_proposed_intent(publishes_id: intent.id)
      assert fetched.publishes_id == intent.id

      assert {:ok, fetched} = Proposals.one_proposed_intent(published_in_id: proposal.id)
      assert fetched.published_in_id == proposal.id
    end

    test "default filter ignores removed items" do
      user = fake_user!()

      proposed_intent =
        fake_proposed_intent!(
          fake_proposal!(user),
          fake_intent!(user)
        )

      assert {:ok, proposed_intent} = Proposals.delete_proposed_intent(proposed_intent)

      assert {:error, %CommonsPub.Common.NotFoundError{}} =
               Proposals.one_proposed_intent([:default, id: proposed_intent.id])
    end
  end

  describe "many_proposed_intent" do
    test "returns a list of items matching criteria" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      intent = fake_intent!(user)

      proposed_intents =
        some(5, fn ->
          fake_proposed_intent!(proposal, intent)
        end)

      assert {:ok, fetched} = Proposals.many_proposed_intents()
      assert Enum.count(fetched) == 5
      assert {:ok, fetched} = Proposals.many_proposed_intents(id: hd(proposed_intents).id)
      assert Enum.count(fetched) == 1
    end
  end

  describe "propose_intent" do
    test "creates a new proposed intent" do
      user = fake_user!()
      intent = fake_intent!(user)
      proposal = fake_proposal!(user)

      assert {:ok, proposed_intent} =
               Proposals.propose_intent(proposal, intent, proposed_intent())

      assert_proposed_intent(proposed_intent)
    end
  end

  describe "delete_proposed_intent" do
    test "deletes an existing proposed intent" do
      user = fake_user!()
      intent = fake_intent!(user)
      proposal = fake_proposal!(user)
      proposed_intent = fake_proposed_intent!(proposal, intent)
      assert {:ok, proposed_intent} = Proposals.delete_proposed_intent(proposed_intent)
      assert proposed_intent.deleted_at
    end
  end

  describe "one_proposed_to" do
    test "fetches an existing item" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      agent = fake_user!()
      proposed_to = fake_proposed_to!(agent, proposal)

      assert {:ok, fetched} = Proposals.one_proposed_to(id: proposed_to.id)
      assert_proposed_to(fetched)
      assert fetched.id == proposed_to.id

      assert {:ok, fetched} = Proposals.one_proposed_to(proposed_to_id: agent.id)
      assert_proposed_to(fetched)
      assert fetched.proposed_to_id == agent.id

      assert {:ok, fetched} = Proposals.one_proposed_to(proposed_id: proposal.id)
      assert_proposed_to(fetched)
      assert fetched.proposed_id == proposal.id
    end

    test "ignores deleted items when using :deleted filter" do
      user = fake_user!()
      proposed_to = fake_proposed_to!(fake_user!(), fake_proposal!(user))
      assert {:ok, proposed_to} = Proposals.delete_proposed_to(proposed_to)

      assert {:error, %CommonsPub.Common.NotFoundError{}} =
               Proposals.one_proposed_to([:deleted, id: proposed_to.id])
    end
  end

  describe "propose_to" do
    test "creates a new proposed to thing" do
      user = fake_user!()
      proposal = fake_proposal!(user)
      agent = fake_user!()
      assert {:ok, proposed_to} = Proposals.propose_to(agent, proposal)
      assert_proposed_to(proposed_to)
    end
  end

  describe "delete_proposed_to" do
    test "deletes an existing proposed to" do
      user = fake_user!()
      proposed_to = fake_proposed_to!(fake_user!(), fake_proposal!(user))

      refute proposed_to.deleted_at
      assert {:ok, proposed_to} = Proposals.delete_proposed_to(proposed_to)
      assert proposed_to.deleted_at
    end
  end
end
