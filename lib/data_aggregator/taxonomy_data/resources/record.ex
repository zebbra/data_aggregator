defmodule DataAggregator.TaxonomyData.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  postgres do
    table "records"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "record"

    attribute :version, :integer do
      allow_nil? false
      filterable? true
    end

    attribute :state, :string do
      allow_nil? false
      filterable? true
    end

    attribute :meta_data, :map

    # further (mandatory) attributes of the core record

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :record

    queries do
      get :get_record, :read
      list :list_records, :read
    end

    mutations do
      create :create_record, :create
      update :update_record, :update
      destroy :destroy_record, :destroy
    end
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
    belongs_to :import, DataAggregator.Imports.Import
    has_many :annotations, DataAggregator.Transition.Annotation
    has_many :record_change_events, DataAggregator.Transition.RecordChangeEvent

    # relate to all the other entities of the taxonomy...
  end
end
