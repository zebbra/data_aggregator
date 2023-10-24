defmodule DataAggregator.Transition.ChangeEvent do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.ImportRecord
  alias DataAggregator.TaxonomyCatalog.Catalog
  alias DataAggregator.TaxonomyData.Record
  alias DataAggregator.Transition.Run

  attributes do
    uuid_attribute :id, prefix: "ce"

    attribute :category, :string do
      allow_nil? false
      filterable? true
    end

    attribute :dwc_attribute, :string

    attribute :value, :string

    attribute :previous_value, :string

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :run, Run

    belongs_to :import_record, ImportRecord do
      api DataAggregator.Imports
    end

    belongs_to :record, Record do
      api DataAggregator.TaxonomyData
    end

    belongs_to :catalog, Catalog do
      api DataAggregator.TaxonomyCatalog
    end
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
