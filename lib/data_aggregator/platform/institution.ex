defmodule DataAggregator.Platform.Institution do
  @moduledoc """
  An institution represents the over all owner of a set of collections.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Platform,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Records.Validations

  attributes do
    uuid_attribute :id, prefix: "ins", public?: true
    attribute :name, :string, allow_nil?: false, public?: true

    attribute :code, :string do
      public? true
      description "an iternationally valid code to identify the institution"
    end

    attribute :address, :string, public?: true
    attribute :zip_code, :string, public?: true
    attribute :city, :string, public?: true
    attribute :country, :string, public?: true
    attribute :mail, :string, public?: true
    attribute :tel, :string, public?: true
    attribute :contact_person, :string, public?: true

    attribute :grscicoll_reference, :string do
      description "a code to identify the institution in the GrSciColl database"
      allow_nil? false
      public? true
    end

    timestamps public?: true, writable?: false
  end

  actions do
    default_accept :*
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define :read
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

  validations do
    validate {Validations.GrSciCollValidator, [attribute: :grscicoll_reference, kind: :institution]} do
      on [:create, :update]
    end
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
      base "/institutions"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
