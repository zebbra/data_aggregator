defmodule DataAggregator.Imports.Institution do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Imports.Collection

  attributes do
    uuid_attribute :id, prefix: "inst"

    attribute :name, :string do
      allow_nil? false
    end

    attribute :address, :string

    attribute :zip_code, :string

    attribute :city, :string

    attribute :country, :string

    attribute :mail, :string

    attribute :tel, :string

    attribute :contact_person, :string

    timestamps private?: false, writable?: false
  end

  relationships do
    has_many :collections, Collection
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Imports
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "institutions"
    repo DataAggregator.Repo
  end

  graphql do
    type :institution

    queries do
      get :get_institution, :read
      list :list_institutions, :read
    end

    mutations do
      create :create_institution, :create
      update :update_institution, :update
      destroy :destroy_institution, :destroy
    end
  end

  json_api do
    type "institution"

    routes do
      base("/institutions")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
