defmodule DataAggregator.Records.Record do
  @moduledoc """
  Ash resource representing a record.

  > #### Info {: .info}
  >
  > All Darwin Core attributes are defined in `DataAggregator.DarwinCore.Schema` and included
  > by the `DataAggregator.DarwinCore.Resource` extension.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [
      AshUUID,
      AshGraphql.Resource,
      AshJsonApi.Resource,
      DataAggregator.DarwinCore.Resource
    ]

  alias DataAggregator.DarwinCore
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import
  alias __MODULE__

  @default_limit 15
  def default_limit, do: @default_limit

  attributes do
    uuid_attribute :id, prefix: "rec"
    attribute :import_data, :map
    attribute :extra_data, :map
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      api DataAggregator.Records
      allow_nil? false
    end

    many_to_many :imports, Import do
      api DataAggregator.Records
      through Import.Record
    end

    has_many :images, Record.Image

    many_to_many :image_attachments, Attachment do
      api DataAggregator.Files
      through Record.Image
      source_attribute_on_join_resource :record_id
      destination_attribute_on_join_resource :attachment_id
      join_relationship :images
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:update, :destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 default_limit: @default_limit,
                 countable: true,
                 required?: false,
                 keyset?: true
    end

    create :create do
      primary? true
      argument :collection, Collection, allow_nil?: false
      change manage_relationship(:collection, :collection, type: :append)
    end

    create :import do
      description """
      Creates or updates a `Record` from the given `params`.

      The record is associated with the give `DataAggregator.Records.Import` and
      its `DataAggregator.Records.Collection`.
      """

      argument :import, Import, allow_nil?: false
      argument :params, :map, allow_nil?: false
      change Record.Changes.RelateImport
      change Record.Changes.RelateCollectionFromImport
      change Record.Changes.ExtractAttributes
      upsert? true
      upsert_identity :collection_mte_material_entity_id
      upsert_fields [:import_data, :extra_data | DarwinCore.Schema.prefixed_attribute_names()]
    end

    action :bulk_import, :map do
      description """
      Imports multiple records using `DataAggregator.Records.bulk_create/3`.

      The `rows` can be any enumberable, where each item which will be used as `params` for
      the `DataAggregator.Records.Record.import/2` action.
      """

      argument :import, Import, allow_nil?: false
      argument :rows, :term, allow_nil?: false
      run Record.Actions.BulkImport
    end
  end

  identities do
    identity :collection_mte_material_entity_id, [:collection_id, :mte_material_entity_id]
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :import, args: [:import, :params]
    define :bulk_import, args: [:import, :rows]
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "records"
    repo DataAggregator.Repo
  end

  graphql do
    type :record

    queries do
      get :get_record, :read
      list :list_records, :read
    end

    mutations do
      update :update_record, :update
      destroy :destroy_record, :destroy
    end
  end

  json_api do
    type "records"

    routes do
      base("/records")

      get(:read)
      index :read
      patch(:update)
      delete(:destroy)
    end
  end
end
