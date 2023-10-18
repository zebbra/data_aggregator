defmodule DataAggregator.Transition.Annotation do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyCatalog.DwcAttribute
  alias DataAggregator.TaxonomyData.Record

  postgres do
    table "annotations"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "ann"

    attribute :comment, :string do
      filterable? true
    end

    attribute :state, :string do
      default "open"
      filterable? true
    end

    attribute :value_suggestion, :string

    attribute :user, :string

    attribute :dwc_attribute_id, :uuid do
      allow_nil? false
      filterable? true
    end

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "annotation"

    routes do
      base("/annotations")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :annotation

    relationships [:record]

    queries do
      get :get_annotation, :read
      list :list_annotations, :read
    end

    mutations do
      create :create_annotation, :create
      update :update_annotation, :update
      destroy :destroy_annotation, :destroy
    end
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
    belongs_to :record, Record do
      api DataAggregator.TaxonomyData
    end

    belongs_to :dwc_attribute, DwcAttribute do
      api DataAggregator.TaxonomyCatalog
    end
  end
end
