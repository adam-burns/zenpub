defmodule ValueFlows.Hydration do
  alias CommonsPub.Web.GraphQL.{
    CommonResolver,
    UploadResolver
  }

  alias CommonsPub.Users.User
  alias CommonsPub.Communities.Community

  def hydrate() do
    agent_fields = %{
      canonical_url: [
        resolve: &CommonsPub.Characters.GraphQL.Resolver.canonical_url_edge/3
      ],
      display_username: [
        resolve: &CommonsPub.Characters.GraphQL.Resolver.display_username_edge/3
      ],
      image: [
        resolve: &UploadResolver.image_content_edge/3
      ]
    }

    %{
      # Type extensions
      uri: [
        parse: &ValueFlows.Util.GraphQL.parse_cool_scalar/1,
        serialize: &ValueFlows.Util.GraphQL.serialize_cool_scalar/1
      ],
      agent: [
        resolve_type: &__MODULE__.agent_resolve_type/2
      ],
      accounting_scope: [
        resolve_type: &__MODULE__.resolve_context_type/2
      ],
      person: agent_fields,
      organization: agent_fields,
      # person: [
      #   is_type_of: &ValueFlows.Agent.GraphQL.person_is_type_of/2
      # ],
      # organization: [
      #   is_type_of: &ValueFlows.Agent.GraphQL.organization_is_type_of/2
      # ],
      proposal: %{
        in_scope_of: [
          resolve: &CommonResolver.context_edge/3
        ],
        eligible_location: [
          resolve: &ValueFlows.Util.GraphQL.at_location_edge/3
        ],
        publishes: [
          resolve: &ValueFlows.Proposal.ProposedIntentGraphQL.publishes_edge/3
        ],
        published_to: [
          resolve: &ValueFlows.Proposal.ProposedToGraphQL.published_to_edge/3
        ],
      },
      intent: %{
        provider: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.fetch_provider_edge/3
        ],
        receiver: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.fetch_receiver_edge/3
        ],
        action: [
          resolve: &ValueFlows.Knowledge.Action.GraphQL.action_edge/3
        ],
        at_location: [
          resolve: &ValueFlows.Util.GraphQL.at_location_edge/3
        ],
        in_scope_of: [
          resolve: &CommonResolver.context_edge/3
        ],
        image: [
          resolve: &UploadResolver.image_content_edge/3
        ],
        resource_classified_as: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.fetch_classifications_edge/3
        ],
        tags: [
          resolve: &CommonsPub.Tag.GraphQL.TagResolver.tags_edges/3
        ],
        published_in: [
          resolve: &ValueFlows.Proposal.ProposedIntentGraphQL.published_in_edge/3
        ]
      },
      economic_event: %{
        resource_inventoried_as: [
          resolve:
            &ValueFlows.Observation.EconomicEvent.GraphQL.fetch_resource_inventoried_as_edge/3
        ]
      },

      # start Query resolvers
      value_flows_query: %{
        # Agents:
        agents: [
          resolve: &ValueFlows.Agent.GraphQL.all_agents/2
        ],
        # agents_pages: [
        #   resolve: &ValueFlows.Agent.GraphQL.agents/2
        # ],
        agent: [
          resolve: &ValueFlows.Agent.GraphQL.agent/2
        ],
        person: [
          resolve: &ValueFlows.Agent.GraphQL.person/2
        ],
        people: [
          resolve: &ValueFlows.Agent.GraphQL.all_people/2
        ],
        people_pages: [
          resolve: &ValueFlows.Agent.GraphQL.people/2
        ],
        organization: [
          resolve: &ValueFlows.Agent.GraphQL.organization/2
        ],
        organizations: [
          resolve: &ValueFlows.Agent.GraphQL.all_organizations/2
        ],
        organizations_pages: [
          resolve: &ValueFlows.Agent.GraphQL.organizations/2
        ],

        # Knowledge
        action: [
          resolve: &ValueFlows.Knowledge.Action.GraphQL.action/2
        ],
        actions: [
          resolve: &ValueFlows.Knowledge.Action.GraphQL.all_actions/2
        ],
        resource_specification: [
          resolve: &ValueFlows.Knowledge.ResourceSpecification.GraphQL.resource_spec/2
        ],
        resource_specifications: [
          resolve: &ValueFlows.Knowledge.ResourceSpecification.GraphQL.all_resource_specs/2
        ],
        process_specification: [
          resolve: &ValueFlows.Knowledge.ProcessSpecification.GraphQL.process_spec/2
        ],
        process_specifications: [
          resolve: &ValueFlows.Knowledge.ProcessSpecification.GraphQL.all_process_specs/2
        ],

        # Observation
        economic_event: [
          resolve: &ValueFlows.Observation.EconomicEvent.GraphQL.event/2
        ],
        economic_events: [
          resolve: &ValueFlows.Observation.EconomicEvent.GraphQL.all_events/2
        ],
        economic_resource: [
          resolve: &ValueFlows.Observation.EconomicResource.GraphQL.resource/2
        ],
        economic_resources: [
          resolve: &ValueFlows.Observation.EconomicResource.GraphQL.all_resources/2
        ],
        process: [
          resolve: &ValueFlows.Observation.Process.GraphQL.simulate/2
        ],
        processes: [
          resolve: &ValueFlows.Observation.Process.GraphQL.simulate/2
        ],

        # Planning
        intent: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.intent/2
        ],
        intents: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.all_intents/2
        ],
        intents_pages: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.intents/2
        ],
        offers_pages: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.offers/2
        ],
        needs_pages: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.needs/2
        ],
        intents_filter: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.intents_filtered/2
        ],

        # Proposal
        proposal: [
          resolve: &ValueFlows.Proposal.GraphQL.proposal/2
        ],
        proposals: [
          resolve: &ValueFlows.Proposal.GraphQL.all_proposals/2
        ],
        proposals_pages: [
          resolve: &ValueFlows.Proposal.GraphQL.proposals/2
        ]
      },

      # end Queries

      # start Mutation resolvers
      value_flows_mutation: %{
        create_intent: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.create_intent/2
        ],
        create_proposal: [
          resolve: &ValueFlows.Proposal.GraphQL.create_proposal/2
        ],
        propose_intent: [
          resolve: &ValueFlows.Proposal.ProposedIntentGraphQL.propose_intent/2
        ],
        propose_to: [
          resolve: &ValueFlows.Proposal.ProposedToGraphQL.propose_to/2
        ],
        create_offer: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.create_offer/2
        ],
        create_need: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.create_need/2
        ],
        # create_action: [
        #   resolve: &ValueFlows.Knowledge.Action.GraphQL.create_action/2
        # ],
        update_intent: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.update_intent/2
        ],
        update_proposal: [
          resolve: &ValueFlows.Proposal.GraphQL.update_proposal/2
        ],
        delete_intent: [
          resolve: &ValueFlows.Planning.Intent.GraphQL.delete_intent/2
        ],
        delete_proposal: [
          resolve: &ValueFlows.Proposal.GraphQL.delete_proposal/2
        ],
        delete_proposed_intent: [
          resolve: &ValueFlows.Proposal.ProposedIntentGraphQL.delete_proposed_intent/2
        ],
        delete_proposed_to: [
          resolve: &ValueFlows.Proposal.ProposedToGraphQL.delete_proposed_to/2
        ],
        create_resource_specification: [
          resolve: &ValueFlows.Knowledge.ResourceSpecification.GraphQL.create_resource_spec/2
        ],
        create_process_specification: [
          resolve: &ValueFlows.Knowledge.ProcessSpecification.GraphQL.create_process_spec/2
        ],
        create_economic_event: [
          resolve: &ValueFlows.Observation.EconomicEvent.GraphQL.create_event/2
        ]
      }
    }
  end

  # support for interface type
  @spec agent_resolve_type(%{agent_type: nil | :organization | :person}, any) ::
          :organization | :person
  def agent_resolve_type(%{agent_type: :person}, _), do: :person
  def agent_resolve_type(%{agent_type: :organization}, _), do: :organization
  def agent_resolve_type(_, _), do: :person
  # def agent_resolve_type(%User{}, _), do: :user

  # def person_is_type_of(_), do: true
  # def organization_is_type_of(_), do: true

  # def resolve_context_type(%Organisation{}, _), do: :organisation
  def resolve_context_type(%Community{}, _), do: :community
  def resolve_context_type(%User{}, _), do: :user
end
