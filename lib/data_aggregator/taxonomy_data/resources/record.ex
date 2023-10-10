defmodule DataAggregator.TaxonomyData.Record do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource]

  alias DataAggregator.Transition.Annotation
  alias DataAggregator.Transition.RecordChangeEvent
  alias DataAggregator.TaxonomyData.Tag
  alias DataAggregator.TaxonomyData.Record2Tag

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
    has_many :annotations, Annotation
    has_many :record_change_events, RecordChangeEvent

    many_to_many :tags, Tag do
      through Record2Tag
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :tag_id
    end

    # relate to all the other entities of the taxonomy...
  end
end
