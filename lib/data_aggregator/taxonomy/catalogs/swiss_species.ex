defmodule DataAggregator.Taxonomy.Catalogs.SwissSpecies do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias __MODULE__

  @type t :: %SwissSpecies{}

  attributes do
    uuid_attribute :id, prefix: "spc"

    attribute :taxon_id_ch, :integer, primary_key?: true, allow_nil?: false
    attribute :accepted_name, :string, allow_nil?: true
    attribute :usage_key, :integer, primary_key?: true, allow_nil?: false
    attribute :accepted_usage_key, :integer, allow_nil?: true
    attribute :scientific_name, :string, allow_nil?: true
    attribute :rank, :string, allow_nil?: true
    attribute :center, :atom, allow_nil?: true

    timestamps private?: false, writable?: false
  end

  relationships do
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Taxonomy
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_usage_key, action: :read, get_by: [:usage_key]
  end

  postgres do
    table "swiss_species"
    repo DataAggregator.Repo
  end

  graphql do
    type :catalog

    queries do
      get :get_swiss_species, :read
      list :list_swiss_species, :read
    end

    mutations do
      create :create_swiss_species, :create
      update :update_swiss_species, :update
      destroy :destroy_swiss_species, :destroy
    end
  end

  json_api do
    type "swiss_species"

    primary_key do
      keys [:id]
    end

    routes do
      base "/swiss_species"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
