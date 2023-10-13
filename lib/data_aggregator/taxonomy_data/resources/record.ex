defmodule DataAggregator.TaxonomyData.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Transition.Annotation
  alias DataAggregator.Transition.RecordChangeEvent
  alias DataAggregator.TaxonomyData.Tag
  alias DataAggregator.TaxonomyData.Record2Tag
  alias DataAggregator.Imports.Import

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
    belongs_to :import, Import do
      api DataAggregator.Imports
    end

    has_many :annotations, Annotation do
      api DataAggregator.Transition
    end

    has_many :record_change_events, RecordChangeEvent do
      api DataAggregator.Transition
    end

    many_to_many :tags, Tag do
      through Record2Tag
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :tag_id
    end

    # relate to all the other entities of the taxonomy...
  end
end
