defmodule DataAggregator.Platform.Publication.Consumer do
  @moduledoc """
  An consumer configures a destination to publish data.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  attributes do
    uuid_attribute :id, prefix: "cos"

    attribute :name, :string, allow_nil?: false

    timestamps private?: false, writable?: false
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Platform
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
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
