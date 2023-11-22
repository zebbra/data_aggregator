defmodule DataAggregator.Platform.Publication.Consumer do
  @moduledoc """
  A consumer represents a destination to publish data.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Platform.Publication.Actions

  attributes do
    uuid_attribute :id, prefix: "cos"

    attribute :name, :string, allow_nil?: false

    attribute :publication_type, :atom,
      allow_nil?: false,
      constraints: [one_of: [:gbif, :dissco, :custom]]

    timestamps private?: false, writable?: false
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    action :collect, :map do
      argument :consumer, :struct, allow_nil?: false

      run Actions.CollectRecords
    end
  end

  code_interface do
    define_for DataAggregator.Platform
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :collect, action: :collect, args: [:consumer]
  end

  postgres do
    table "consumers"
    repo DataAggregator.Repo
  end

  graphql do
    type :consumer

    queries do
      get :get_consumer, :read
      list :list_consumers, :read
    end

    mutations do
      create :create_consumer, :create
      update :update_consumer, :update
      destroy :destroy_consumer, :destroy
    end
  end

  json_api do
    type "consumer"

    routes do
      base("/consumers")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
