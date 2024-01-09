defmodule DataAggregator.Records.ChangeEvent do
  @moduledoc """
  Resource representing a change event of a `DataAggregator.Records.Record`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Records.ChangeEvent.EventCategory
  alias DataAggregator.Records.Record

  attributes do
    uuid_attribute :id, prefix: "che"

    attribute :dwc_attribute, :atom, allow_nil?: false
    attribute :value, :string, allow_nil?: true
    attribute :previous_value, :string, allow_nil?: true
    attribute :category, EventCategory, allow_nil?: false

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :record, Record
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      argument :record, Record

      change manage_relationship(:record, :record, type: :append)
    end

    update :update do
      primary? true
      argument :record, Record

      change manage_relationship(:record, :record, type: :append)
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "change_events"
    repo DataAggregator.Repo
  end

  graphql do
    type :change_event

    queries do
      get :get_change_event, :read
      list :list_change_events, :read
    end

    mutations do
      create :create_change_event, :create
      update :update_change_event, :update
      destroy :destroy_change_event, :destroy
    end
  end

  json_api do
    type "change_event"

    routes do
      base("/change_events")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
