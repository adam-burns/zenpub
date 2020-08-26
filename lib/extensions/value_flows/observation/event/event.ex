defmodule ValueFlows.Observation.EconomicEvent do
  use Pointers.Pointable,
    otp_app: :moodle_net,
    source: "vf_event",
    table_id: "ACTVA10BSERVEDF10WS0FVA1VE"

  import MoodleNet.Common.Changeset, only: [change_public: 1, change_disabled: 1]

  alias Ecto.Changeset
  alias MoodleNet.Users.User
  # alias MoodleNet.Actors.Actor
  # alias MoodleNet.Communities.Community
  alias ValueFlows.Knowledge.Action
  alias ValueFlows.Observation.EconomicEvent
  alias ValueFlows.Observation.EconomicResource

  alias Measurement.Measure

  @type t :: %__MODULE__{}

  pointable_schema do
    field(:name, :string)
    field(:note, :string)

    belongs_to(:image, Content)

    belongs_to(:action, Action, type: :string)

    belongs_to(:input_of, Process)
    belongs_to(:output_of, Process)

    belongs_to(:provider, Pointers.Pointer)
    belongs_to(:receiver, Pointers.Pointer)

    belongs_to(:resource_inventoried_as, EconomicResource)
    belongs_to(:to_resource_inventoried_as, EconomicResource)

    field(:resource_classified_as, {:array, :string}, virtual: true)
    belongs_to(:resource_conforms_to, ResourceSpecification)

    belongs_to(:resource_quantity, Measure, on_replace: :nilify)
    belongs_to(:effort_quantity, Measure, on_replace: :nilify)

    field(:has_beginning, :utc_datetime_usec)
    field(:has_end, :utc_datetime_usec)
    field(:has_point_in_time, :utc_datetime_usec)

    belongs_to(:context, Pointers.Pointer)

    field(:agreed_in, :string)

    belongs_to(:at_location, SpatialThing)

    belongs_to(:triggered_by, EconomicEvent)

    # TODO:
    # track: [ProductionFlowItem!]
    # trace: [ProductionFlowItem!]
    # realizationOf: Agreement
    # appreciationOf: [Appreciation!]
    # appreciatedBy: [Appreciation!]
    # fulfills: [Fulfillment!]
    # satisfies: [Satisfaction!]
    # field(:deletable, :boolean) # TODO - virtual field? how is it calculated?

    belongs_to(:creator, User)

    field(:is_public, :boolean, virtual: true)
    field(:published_at, :utc_datetime_usec)
    field(:is_disabled, :boolean, virtual: true, default: false)
    field(:disabled_at, :utc_datetime_usec)
    field(:deleted_at, :utc_datetime_usec)

    many_to_many(:tags, CommonsPub.Tag.Taggable,
      join_through: "tags_things",
      unique: true,
      join_keys: [pointer_id: :id, tag_id: :id],
      on_replace: :delete
    )

    timestamps(inserted_at: false)
  end

  @required ~w(name is_public)a
  @cast @required ++ ~w(note at_location_id is_disabled image_id)a

  def create_changeset(
        %User{} = creator,
        %Action{} = action,
        %{id: _} = context,
        attrs
      ) do
    %EconomicEvent{}
    |> Changeset.cast(attrs, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.change(
      creator_id: creator.id,
      context_id: context.id,
      # TODO: move action to context and validate that it's a valid action
      action_id: action.id,
      is_public: true
    )
    |> common_changeset()
  end

  def create_changeset(
        %User{} = creator,
        %Action{} = action,
        attrs
      ) do
    %EconomicEvent{}
    |> Changeset.cast(attrs, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.change(
      creator_id: creator.id,
      action_id: action.id,
      is_public: true
    )
    |> common_changeset()
  end

  def update_changeset(
        %EconomicEvent{} = event,
        %{id: _} = context,
        attrs
      ) do
    event
    |> Changeset.cast(attrs, @cast)
    |> Changeset.change(context_id: context.id)
    |> common_changeset()
  end

  def update_changeset(%EconomicEvent{} = event, attrs) do
    event
    |> Changeset.cast(attrs, @cast)
    |> common_changeset()
  end

  def measure_fields do
    [:resource_quantity, :effort_quantity, :available_quantity]
  end

  def change_measures(changeset, %{} = attrs) do
    measures = Map.take(attrs, measure_fields())

    Enum.reduce(measures, changeset, fn {field_name, measure}, c ->
      Changeset.put_assoc(c, field_name, measure)
    end)
  end

  def change_at_location(changeset, %Geolocation{} = location) do
    Changeset.change(changeset,
      at_location: location,
      at_location_id: location.id
    )
  end

  def change_action(changeset, %Action{} = action) do
    Changeset.change(changeset, action_id: action.id)
  end

  def change_provider(changeset, %{id: _} = provider) do
    Changeset.change(changeset, provider_id: provider.id)
  end

  def change_receiver(changeset, %{id: _} = receiver) do
    Changeset.change(changeset, receiver_id: receiver.id)
  end

  defp common_changeset(changeset) do
    changeset
    |> change_public()
    |> change_disabled()
    |> Changeset.foreign_key_constraint(
      :at_location_id,
      name: :vf_event_at_location_id_fkey
    )
  end

  def context_module, do: ValueFlows.Observation.EconomicEvent.EconomicEvents

  def queries_module, do: ValueFlows.Observation.EconomicEvent.Queries

  def follow_filters, do: [:default]
end
