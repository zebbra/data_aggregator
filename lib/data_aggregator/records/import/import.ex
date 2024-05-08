flow_chart = Path.expand("import-mermaid-flowchart.md", __DIR__)

defmodule DataAggregator.Records.Import do
  @moduledoc """
  Resource for importing records into a collection from a file.

  ## Flow Chart

  #{File.read!(flow_chart)}
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import.Column
  alias DataAggregator.Records.Import.Record, as: ImportRecord
  alias DataAggregator.Records.Record

  require Ash.Resource.Change.Builtins

  # ensure module is recompiled when the flow chart changes
  @external_resource flow_chart

  @default_limit 15
  def default_limit, do: @default_limit

  attributes do
    uuid_attribute :id, prefix: "if"

    attribute :columns, {:array, Column} do
      constraints load: [:mapped?]
    end

    timestamps private?: false, writable?: false

    attribute :started_at, :utc_datetime, allow_nil?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true

    attribute :rows_count, :integer, allow_nil?: true
    attribute :rows_valid_count, :integer, allow_nil?: true
    attribute :rows_invalid_count, :integer, allow_nil?: true
    attribute :rows_imported_count, :integer, allow_nil?: true
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
    end

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    many_to_many :records, Record do
      through ImportRecord
      join_relationship :import_records
    end

    belongs_to :job, Job do
      api DataAggregator.Jobs
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
    end
  end

  calculations do
    calculate :import_progress, :float, expr(rows_imported_count / rows_count)
    calculate :rows_validated_count, :integer, expr(rows_valid_count + rows_invalid_count)

    calculate :rows_valid_ratio,
              :float,
              expr(if rows_validated_count > 0, do: rows_valid_count / rows_validated_count)

    calculate :validation_progress, :float, expr(rows_validated_count / rows_count)

    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn import, _opts -> import.attachment.url end
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

      load attachment: :url
    end

    calculate :mappings, {:array, Column}, Import.Calculations.Mappings
    calculate :missing_mappings, :map, Import.Calculations.MissingMappings
  end

  aggregates do
    count :records_count, :records
  end

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :update_mapping, from: [:pending, :failed, :imported], to: :pending
      transition :enqueue_import, from: [:pending, :failed, :imported], to: :import_queued
      transition :import, from: [:pending, :import_queued], to: :importing
      transition :import, from: [:importing], to: :imported
      transition :set_imported, from: :importing, to: :imported
      transition :set_failed, from: :importing, to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :desc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 default_limit: @default_limit,
                 countable: true,
                 required?: false,
                 keyset?: true
    end

    read :by_collection do
      argument :collection_id, :string, allow_nil?: false
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 default_limit: @default_limit,
                 countable: true,
                 required?: false,
                 keyset?: true

      filter expr(collection_id == ^arg(:collection_id))
    end

    create :create do
      primary? true
      argument :collection, Collection, allow_nil?: false
      change manage_relationship(:collection, :collection, type: :append)
    end

    create :create_from_path do
      accept []
      argument :collection, Collection, allow_nil?: false
      argument :path, :string, allow_nil?: false
      argument :filename, :string, allow_nil?: true
      change manage_relationship(:collection, :collection, type: :append)
      change Import.Changes.CreateAttachment
      change Import.Changes.DetectColumns
      change Import.Changes.CountRows
      change load([:attachment_filename, :attachment_byte_size])
    end

    update :update_mapping do
      accept [:columns]
      change Import.Changes.UpdateMapping
      change transition_state(:pending)
      change load([:missing_mappings, :mappings])
    end

    update :add_validation_progress do
      accept []
      argument :valid, :integer, allow_nil?: false
      argument :invalid, :integer, allow_nil?: false
      change atomic_update(:rows_valid_count, expr(rows_valid_count + ^arg(:valid)))
      change atomic_update(:rows_invalid_count, expr(rows_invalid_count + ^arg(:invalid)))
      change ensure_selected(:rows_valid_count)
      change ensure_selected(:rows_invalid_count)
    end

    update :enqueue_import do
      accept []
      change transition_state(:import_queued)
      change Import.Changes.EnqueueImporter
      change load(:job)
    end

    update :import do
      accept []
      change Import.Changes.SetTimeout
      change Import.Changes.SetImportingBeforeTransaction
      change Import.Changes.ValidateRows
      change Import.Changes.ImportRecords
      change Import.Changes.SetImportedAfterAction
      change Import.Changes.SetFailedOnError
      change load(:records_count)
    end

    update :set_importing do
      accept []
      change set_attribute(:state, :importing)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
      change set_attribute(:rows_imported_count, 0)
      change set_attribute(:rows_valid_count, 0)
      change set_attribute(:rows_invalid_count, 0)
    end

    update :add_import_progress do
      accept []
      argument :imported, :integer, allow_nil?: false
      change atomic_update(:rows_imported_count, expr(rows_imported_count + ^arg(:imported)))
      change ensure_selected(:rows_imported_count)
    end

    update :set_failed do
      accept []
      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change set_attribute(:rows_imported_count, 0)
    end

    update :set_imported do
      accept []
      change transition_state(:imported)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "import"

    publish_all :create, [[:collection_id, nil], "created"]
    publish_all :update, [[:collection_id, nil], "updated", [:id, nil]]
    publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]

    # not used yet, just as an example how to extend this
    # publish :set_failed, [[:collection_id, nil], "failed", [:id, nil]]
    # publish :set_imported, [[:collection_id, nil], "imported", [:id, nil]]
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :by_collection, args: [:collection_id]
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
  end

  postgres do
    table "imports"
    repo DataAggregator.Repo
  end

  graphql do
    type :import

    queries do
      get :get_import, :read
      list :list_imports, :read
    end

    mutations do
      create :create_import, :create_from_path
    end
  end

  json_api do
    type "import"

    routes do
      base "/imports"

      get :read
      index :read
      post :create_from_path
    end
  end
end
