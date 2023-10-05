defmodule DataAggregator.Transition.Annotation do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  postgres do
    table "annotations"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "annotation"

    attribute :state, :string do
      allow_nil? false
      filterable? true
    end

    attribute :comment, :string do
      allow_nil? false
      filterable? true
    end

    attribute :value_suggestion, :string

    attribute :user, :string

    attribute :dwc_attribute_id, :uuid

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
