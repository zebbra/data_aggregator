defmodule DataAggregator.Imports.ImportChangeEvent do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.ImportRecord
  alias DataAggregator.Transition.ChangeEvent

  attributes do
    uuid_attribute :id, prefix: "ice"

    timestamps()
  end

  relationships do
    belongs_to :import_record, ImportRecord

    belongs_to :change_event, ChangeEvent do
      api DataAggregator.Transition
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Imports
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "import_change_events"
    repo DataAggregator.Repo
  end

  graphql do
    type :import_change_event

    queries do
      get :get_import_change_event, :read
      list :list_import_change_events, :read
    end

    mutations do
      create :create_import_change_event, :create
      update :update_import_change_event, :update
      destroy :destroy_import_change_event, :destroy
    end
  end

  json_api do
    type "import_change_event"

    routes do
      base("/import_change_events")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
