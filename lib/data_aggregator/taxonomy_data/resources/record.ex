defmodule DataAggregator.TaxonomyData.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID]

  alias DataAggregator.Transition.Annotation
  alias DataAggregator.Transition.RecordChangeEvent

  postgres do
    table "records"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "record"

    attribute :unique_qualifier, :string do
      allow_nil? false
    end

    attribute :state, :string do
      allow_nil? false
      filterable? true
    end

    attribute :meta_data, :map

    attribute :import_id, :uuid do
      allow_nil? false
      filterable? true
    end

    # further (mandatory) attributes of the core record

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.TaxonomyData
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  relationships do
    has_many :annotations, Annotation
    has_many :record_change_events, RecordChangeEvent

    # relate to all the other entities of the taxonomy...
  end
end
