defmodule DataAggregator.Import.Provider do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource]

  postgres do
    table "providers"
    repo DataAggregator.Repo
  end

  calculations do
    calculate :test, :string, expr("#" <> " " <> name)
    calculate :contains_test, :boolean, expr("contains(#, ?)", "test")
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      filterable? true
    end

    attribute :address, :string do
      allow_nil? false
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  graphql do
    type :provider

    queries do
      get :get_provider, :read
      list :list_providers, :read
    end

    mutations do
      create :create_provider, :create
      update :update_provider, :update
      destroy :destroy_provider, :destroy
    end
  end

  code_interface do
    define_for DataAggregator.Import
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
  end
end
