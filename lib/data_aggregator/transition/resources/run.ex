defmodule DataAggregator.Transition.Run do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.TaxonomyData.Record2Run
  alias DataAggregator.Imports.ImportRecord2Run
  alias DataAggregator.TaxonomyData.Record
  alias DataAggregator.TaxonomyCatalog.AttributeResolvingStrategy2Run

  postgres do
    table "runs"
    repo DataAggregator.Repo
  end

  attributes do
    uuid_attribute :id, prefix: "run"

    attribute :comment, :string do
      filterable? true
    end

    attribute :state, :string do
      default "open"
      filterable? true
    end

    attribute :value_suggestion, :string

    attribute :user, :string

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  json_api do
    type "run"

    routes do
      base("/runs")

      get(:read)
      index(:read)
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end

  graphql do
    type :run

    relationships [:record]

    queries do
      get :get_run, :read
      list :list_runs, :read
    end

    mutations do
      create :create_run, :create
      update :update_run, :update
      destroy :destroy_run, :destroy
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
    has_many :importRecords2runs, ImportRecord2Run do
      api DataAggregator.Imports
    end

    has_many :attribute_resolving_strategies2runs, AttributeResolvingStrategy2Run do
      api DataAggregator.TaxonomyCatalog
    end

    many_to_many :records, Record do
      api DataAggregator.TaxonomyData
      through Record2Run
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :run_id
    end

    has_many :runs_join_assoc, DataAggregator.TaxonomyData.Record2Run do
      api DataAggregator.TaxonomyData
    end
  end
end
