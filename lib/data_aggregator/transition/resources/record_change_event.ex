defmodule DataAggregator.Transition.RecordChangeEvent do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  postgres do
    table "record_change_events"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "record_change_event"

    attribute :category, :string do
      allow_nil? false
      filterable? true
    end

    attribute :value, :string

    attribute :previous_value, :string

    attribute :catalog_value_ref, :integer

    attribute :dwc_attribute_id, :uuid

    attribute :catalog_id, :uuid

    attribute :record_id, :uuid

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Transition
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
  end
end
