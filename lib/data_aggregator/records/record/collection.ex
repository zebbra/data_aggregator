defmodule DataAggregator.Records.Collection do
  @moduledoc """
  Resource representing a collection of records.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource],
    notifiers: [Ash.Notifier.PubSub]

  alias DataAggregator.Records
  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.Export.Calculations
  alias DataAggregator.Records.Validations

  @default_limit 15
  def default_limit, do: @default_limit

  attributes do
    uuid_attribute :id, prefix: "col"

    attribute :items_to_digitize, :integer, allow_nil?: false, default: 0
    attribute :owner, :string, allow_nil?: false

    attribute :name, :string do
      allow_nil? false
    end

    attribute :code, :string do
      description "an iternationally valid code to identify the collection"
    end

    attribute :grscicoll_reference, :string do
      description "a code to identify the collection in the GrSciColl database"
      allow_nil? false
    end

    attribute :description, :string

    attribute :import_mapping, {:array, :map}

    attribute :type, CollectionType, default: :other

    # allow sorting by inserted_at/updated_at
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :institution, DataAggregator.Platform.Institution do
      api DataAggregator.Platform
    end

    has_many :imports, DataAggregator.Records.Import do
      api DataAggregator.Records
    end

    has_many :exports, DataAggregator.Records.Export do
      api DataAggregator.Records
    end

    has_many :records, DataAggregator.Records.Record do
      api DataAggregator.Records
    end
  end

  calculations do
    calculate :digitizing_progress,
              :float,
              expr(
                if(
                  items_to_digitize > 0 and records_count > 0,
                  do: 100 * records_count / items_to_digitize,
                  else: 0
                )
              )

    calculate :encoding_state,
              :atom,
              expr(
                cond do
                  records_count_encoded == records_count ->
                    :encoded

                  records_count_encoding > 0 or
                      records_count_encoding_queued > 0 ->
                    :encoding

                  records_count_failed > 0 ->
                    :failed

                  records_count > records_count_encoded ->
                    :incomplete

                  true ->
                    :unknown
                end
              )

    calculate :records_to_export_query, :map, Calculations.RecordsToExport
  end

  aggregates do
    count :records_count, :records
    count :imports_count, :imports

    count :records_count_not_encoded, :records do
      filter expr(
               state == :imported or
                 state == :queued or
                 state == :encoding or
                 state == :failed
             )
    end

    count :records_count_imported, :records do
      filter expr(state == :imported)
    end

    count :records_count_encoding_queued, :records do
      filter expr(state == :queued)
    end

    count :records_count_encoding, :records do
      filter expr(state == :encoding)
    end

    count :records_count_encoded, :records do
      filter expr(state == :encoded)
    end

    count :records_count_failed, :records do
      filter expr(state == :failed)
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:create, :update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 default_limit: @default_limit,
                 countable: true,
                 required?: false,
                 keyset?: true
    end

    update :update_import_mapping do
      accept [:import_mapping]
    end

    update :touch do
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    action :publish, :map do
      argument :export, :struct, allow_nil?: false

      run Records.Actions.PublishRecords
    end

    action :export, :map do
      argument :export, :struct, allow_nil?: false

      run Records.Actions.ExportRecords
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "collection"

    publish_all :create, ["created", [:id, nil]]
    publish_all :update, ["updated", [:id, nil]]
    publish_all :destroy, ["destroyed", [:id, nil]]
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :update_import_mapping, args: [:import_mapping]
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :touch
    define :publish, action: :publish, args: [:publish]
    define :export, action: :export, args: [:export]
  end

  postgres do
    table "collections"
    repo DataAggregator.Repo
  end

  validations do
    validate {Validations.GrSciCollValidator, [attribute: :grscicoll_reference, kind: :collection]} do
      on [:create, :update]
    end
  end

  graphql do
    type :collection

    queries do
      get :get_collection, :read
      list :list_collections, :read
    end

    mutations do
      create :create_collection, :create
      update :update_collection, :update
      destroy :destroy_collection, :destroy
    end
  end

  json_api do
    type "collection"

    routes do
      base "/collections"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
