flow_chart = Path.expand("import-mermaid-flowchart.md", __DIR__)

defmodule DataAggregator.Records.Import do
  @moduledoc """
  Resource for importing records into a collection from a file.

  ## Flow Chart

  #{File.read!(flow_chart)}
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Accounts.User
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction
  alias DataAggregator.Records.Import.Column
  alias DataAggregator.Records.Import.Record, as: ImportRecord
  alias DataAggregator.Records.Record

  require Ash.Resource.Change.Builtins

  @type t :: %Import{}

  # ensure module is recompiled when the flow chart changes
  @external_resource flow_chart

  attributes do
    uuid_attribute :id, prefix: "if", public?: true

    attribute :columns, {:array, Column} do
      constraints load: [:mapped?]
      public? true
    end

    timestamps public?: true, writable?: false

    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true

    attribute :rows_count, :integer, allow_nil?: true, public?: true
    attribute :rows_valid_count, :integer, allow_nil?: true, public?: true
    attribute :rows_invalid_count, :integer, allow_nil?: true, public?: true
    attribute :rows_imported_count, :integer, allow_nil?: true, public?: true
    attribute :rows_error_count, :integer, allow_nil?: true, public?: true
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
      public? true
    end

    belongs_to :created_by, User, public?: true
    belongs_to :started_by, User, public?: true
    belongs_to :attachment, Attachment, public?: true
    belongs_to :error_log, Attachment, public?: true

    many_to_many :records, Record do
      through ImportRecord
      join_relationship :import_records
      public? true
    end
  end

  calculations do
    calculate :import_progress,
              :float,
              expr(if rows_count > 0, do: rows_imported_count / rows_count, else: 1.0)

    calculate :rows_validated_count, :integer, expr(rows_valid_count + rows_invalid_count)

    calculate :rows_valid_ratio,
              :float,
              expr(if rows_validated_count > 0, do: rows_valid_count / rows_validated_count)

    calculate :validation_progress,
              :float,
              expr(if rows_count > 0, do: rows_validated_count / rows_count, else: 1.0)

    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn imports, _opts ->
        Enum.map(imports, & &1.attachment.url)
      end

      load attachment: :url
    end

    calculate :attachment_byte_size, :integer, expr(attachment.byte_size)
    calculate :attachment_filename, :string, expr(attachment.filename)

    calculate :attachment_data, :term, Import.Calculations.AttachmentData do
      description """
      Returns an `Explorer.DataFrame` calculated by `DataAggregator.Records.Import.Calculations.AttachmentData`.

      ## Arguments

      * `mapped` - If If `true`, the column names are mapped to the names defined in the import mapping.
                   If `false`, the column names are the same as the column names in the file.
                   Defaults to `false`.
      """

      argument :mapped, :boolean, default: false

      load attachment: [:filename, :url]
    end

    calculate :mappings, {:array, Column}, Import.Calculations.Mappings
    calculate :missing_mappings, :map, Import.Calculations.MissingMappings
  end

  aggregates do
    count :records_count, :records, public?: true
  end

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :update_mapping, from: [:pending, :failed, :imported], to: :pending
      transition :enqueue_import, from: [:pending, :failed, :imported], to: :import_queued
      transition :import, from: [:pending, :import_queued], to: :importing
      transition :import, from: [:importing], to: :imported
      transition :set_importing, from: [:pending, :import_queued], to: :importing
      transition :set_imported, from: :importing, to: :imported
      transition :set_failed, from: :importing, to: :failed
      transition :cancel_import, from: [:importing, :import_queued], to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :desc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read, :destroy, :update]

    read :active do
      filter expr(state in [:importing, :import_queued])
    end

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false
      change manage_relationship(:collection, type: :append)
    end

    create :create_from_path do
      accept [:created_by_id]
      argument :collection, :struct, allow_nil?: false
      argument :path, :string, allow_nil?: false
      argument :filename, :string, allow_nil?: true
      change manage_relationship(:collection, type: :append)
      change Import.Changes.CreateAttachment
      change Import.Changes.DetectColumns
      change Import.Changes.CountRows
      change load([:attachment_filename, :attachment_byte_size])
    end

    update :update_mapping do
      accept [:columns]
      require_atomic? false

      change Import.Changes.UpdateMapping
      change transition_state(:pending)
      change load([:missing_mappings, :mappings, :collection])
    end

    update :add_validation_progress do
      accept []
      argument :valid, :integer, allow_nil?: false
      argument :invalid, :integer, allow_nil?: false
      require_atomic? false

      change atomic_update(:rows_valid_count, expr(rows_valid_count + ^arg(:valid)))
      change atomic_update(:rows_invalid_count, expr(rows_invalid_count + ^arg(:invalid)))
      change ensure_selected(:rows_valid_count)
      change ensure_selected(:rows_invalid_count)
    end

    update :enqueue_import do
      accept [:started_by_id]
      require_atomic? false

      change Import.Changes.SetCollectionImportingBeforeTransaction
      change transition_state(:import_queued)
      change Import.Changes.EnqueueImporter
    end

    update :import do
      accept []
      require_atomic? false

      change Import.Changes.SetTimeout
      change Import.Changes.SetImportingBeforeTransaction
      change Import.Changes.ValidateRows
      change Import.Changes.ImportRecords
      change Import.Changes.SetImportedAfterAction
      change Import.Changes.SetFailedOnError
      change Import.Changes.SetRecordsCountAfterTransaction
      change load(:records_count)
    end

    update :set_importing do
      accept []
      require_atomic? false

      change transition_state(:importing)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
      change set_attribute(:rows_imported_count, 0)
      change set_attribute(:rows_valid_count, 0)
      change set_attribute(:rows_invalid_count, 0)
      change set_attribute(:rows_error_count, 0)
    end

    update :add_import_progress do
      accept []
      argument :imported, :integer, allow_nil?: false
      change atomic_update(:rows_imported_count, expr(rows_imported_count + ^arg(:imported)))
      change ensure_selected(:rows_imported_count)
    end

    update :set_failed do
      accept []
      require_atomic? false

      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change set_attribute(:rows_imported_count, 0)
      change SetCollectionIdleAfterTransaction
    end

    update :set_imported do
      accept []
      require_atomic? false

      change transition_state(:imported)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change SetCollectionIdleAfterTransaction
    end

    update :update_error_log do
      accept []
      argument :error_log, :struct, allow_nil?: false
      require_atomic? false

      change manage_relationship(:error_log, type: :append)
      change load(:error_log)
    end

    update :cancel_import do
      accept []
      require_atomic? false

      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "import"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
    publish :set_importing, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_imported, [[:collection_id, nil], "updated", [:id, nil]]
    publish :set_failed, [[:collection_id, nil], "updated", [:id, nil]]
    publish :update_mapping, [[:collection_id, nil], "updated", [:id, nil]]
    publish :add_import_progress, [[:collection_id, nil], "updated", [:id, nil]]
  end

  code_interface do
    define :read
    define :update
    define :get_by_id, action: :read, get_by: [:id]
    define :active
    define :create, args: [:collection]
    define :create_from_path, args: [:collection, :path]
    define :update_mapping, args: [:columns]
    define :enqueue_import
    define :import
    define :set_importing
    define :add_import_progress, args: [:imported]
    define :add_validation_progress, args: [:valid, :invalid]
    define :set_imported
    define :set_failed
    define :destroy
    define :update_error_log, args: [:error_log]
    define :cancel_import
  end

  postgres do
    table "imports"
    repo DataAggregator.Repo

    references do
      reference :collection, on_delete: :delete, on_update: :update, index?: true
      reference :error_log, on_delete: :delete, on_update: :update, index?: true
    end
  end

  json_api do
    type "imports"

    routes do
      base "/datasets/:collection_id/imports"

      get :read
      index :read
      post :create_from_path

      patch :update_mapping,
        route: "/:id/update_mapping",
        query_params: [:columns],
        default_fields: [:id, :columns]

      delete :destroy
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
