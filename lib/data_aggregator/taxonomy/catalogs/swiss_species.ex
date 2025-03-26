defmodule DataAggregator.Taxonomy.Catalogs.SwissSpecies do
  @moduledoc false

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Taxonomy,
    extensions: [AshUUID, AshJsonApi.Resource]

  alias __MODULE__

  @type t :: %SwissSpecies{}

  attributes do
    uuid_attribute :id, prefix: "spc", public?: true

    attribute :taxon_id_ch, :integer, allow_nil?: true, public?: true
    attribute :accepted_name, :string, allow_nil?: true, public?: true
    attribute :usage_key, :integer, primary_key?: true, allow_nil?: false, public?: true
    attribute :accepted_usage_key, :integer, allow_nil?: true, public?: true
    attribute :scientific_name, :string, allow_nil?: true, public?: true
    attribute :rank, :string, allow_nil?: true, public?: true
    attribute :center, :atom, allow_nil?: true, public?: true

    timestamps public?: true, writable?: false
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
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
