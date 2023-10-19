defmodule DataAggregator.Transition.EncodingChangeEvent do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyCatalog.Catalog
  alias DataAggregator.TaxonomyData.Record
  alias DataAggregator.Transition.ChangeEvent

  attributes do
    uuid_attribute :id, prefix: "ece"

    attribute :catalog_value_reference, :string

    timestamps()
  end

  graphql do
    type :encoding_change_event

    queries do
      get :get_encoding_change_event, :read
      list :list_encoding_change_events, :read
    end

    mutations do
      create :create_encoding_change_event, :create
      update :update_encoding_change_event, :update
      destroy :destroy_encoding_change_event, :destroy
    end
  end

  json_api do
    type "encoding_change_event"

    routes do
      base("/encoding_change_events")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  relationships do
    belongs_to :change_event, ChangeEvent

    belongs_to :catalog, Catalog do
      api DataAggregator.TaxonomyCatalog
    end

    belongs_to :record, Record do
      api DataAggregator.TaxonomyData
    end
  end

  postgres do
    table "encoding_change_events"
    repo DataAggregator.Repo
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
end
