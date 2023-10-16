defmodule DataAggregator.TaxonomyData.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Transition.Annotation
  alias DataAggregator.Transition.EncodingChangeEvent
  alias DataAggregator.TaxonomyData.Record2Run
  alias DataAggregator.Imports.ImportRecord
  alias DataAggregator.Transition.Run

  postgres do
    table "records"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "record"

    attribute :unique_qualifier, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    # further (mandatory) attributes of the core record

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "record"

    routes do
      base("/records")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
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
    belongs_to :import_record, ImportRecord do
      api DataAggregator.Imports
    end

    has_many :annotations, Annotation do
      api DataAggregator.Transition
    end

    has_many :record_change_events, EncodingChangeEvent do
      api DataAggregator.Transition
    end

    many_to_many :runs, Run do
      api DataAggregator.Transition
      through Record2Run
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :run_id
    end

    has_many :runs_join_assoc, DataAggregator.TaxonomyData.Record2Run do
    end
  end
end
