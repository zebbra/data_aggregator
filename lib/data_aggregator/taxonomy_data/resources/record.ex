defmodule DataAggregator.TaxonomyData.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.ImportRecord
  alias DataAggregator.Transition.Annotation
  alias DataAggregator.Transition.EncodingChangeEvent

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

  json_api do
    type "record"

    routes do
      base("/records")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  attributes do
    uuid_attribute :id, prefix: "rec"

    attribute :unique_qualifier, :string do
      allow_nil? false
    end

    attribute :meta_data, :map

    # further attributes of the core record

    timestamps()
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
  end

  postgres do
    table "records"
    repo DataAggregator.Repo
  end

  code_interface do
    define_for DataAggregator.TaxonomyData
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end
end
