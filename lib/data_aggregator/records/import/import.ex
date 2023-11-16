defmodule DataAggregator.Records.Import do
  @moduledoc """
  Resource for importing records into a collection from a file.

  ## Flow Chart

  #{"import-mermaid-flowchart.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import.Column
  alias DataAggregator.Records.Import.Record, as: ImportRecord

  attributes do
    uuid_attribute :id, prefix: "if"
    attribute :columns, {:array, Column}
    timestamps private?: false, writable?: false
    attribute :imported_at, :utc_datetime, allow_nil?: true
  end

  relationships do
    belongs_to :collection, Collection do
      allow_nil? false
    end

    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    many_to_many :records, DataAggregator.Records.Record do
      api DataAggregator.Records
      through ImportRecord
      join_relationship :import_records
    end
  end

  calculations do
    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn import, _opts -> import.attachment.url end
      load attachment: :url
    end

    calculate :attachment_byte_size, :integer, expr(attachment.byte_size)
    calculate :attachment_filename, :string, expr(attachment.filename)

    calculate :attachment_data, :term, Import.Calculations.AttachmentData do
      argument :mapped, :boolean, default: false
      load attachment: :url
    end
  end

  aggregates do
    count :records_count, :records
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

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :enqueue, from: [:pending, :imported, :failed], to: :queued
      transition :run, from: [:pending, :imported, :failed, :queued], to: :running
      transition :set_imported, from: :running, to: :imported
      transition :set_failed, from: :running, to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:destroy]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
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
      change DataAggregator.Records.Import.Changes.CreateAttachment
      change DataAggregator.Records.Import.Changes.DetectColumns
      change load([:attachment_filename, :attachment_byte_size])
    end

    update :update_mapping do
      accept [:columns]
      change Import.Changes.UpdateMapping
    end

    update :run do
      accept []
      change Import.Changes.SetRunningBeforeTransaction
      change transition_state(:running)
      change Import.Changes.ImportRecords
      change Import.Changes.SetImportedAfterAction
      change Import.Changes.SetFailedOnError
      change load(:records_count)
    end

    update :enqueue do
      change transition_state(:queued)
      change Import.Changes.EnqueueRunner
    end

    update :set_running do
      accept []
      change set_attribute(:state, :running)
    end

    update :set_failed do
      accept []
      change transition_state(:failed)
    end

    update :set_imported do
      accept []
      change set_attribute(:imported_at, &DateTime.utc_now/0)
      change transition_state(:imported)
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :create, args: [:collection]
    define :create_from_path, args: [:collection, :path]
    define :update_mapping, args: [:columns]
    define :run
    define :enqueue
    define :set_running
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
      base("/imports")

      get(:read)
      index :read
      post(:create_from_path)
    end
  end
end
