defmodule DataAggregator.TaxonomyData.Record2Tag do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyData.Record
  alias DataAggregator.TaxonomyData.Tag

  postgres do
    table "records2tags"
    repo DataAggregator.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "record2tag"

    primary_key do
      keys([:record_id, :tag_id])
      delimiter("~")
    end

    routes do
      base("/records2tags")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :record2tag

    queries do
      get :get_record2tag, :read
      list :list_records2tags, :read
    end

    mutations do
      create :create_record2tag, :create
      update :update_record2tag, :update
      destroy :destroy_record2tag, :destroy
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
    belongs_to :record, Record, primary_key?: true, allow_nil?: false
    belongs_to :tag, Tag, primary_key?: true, allow_nil?: false
  end
end
