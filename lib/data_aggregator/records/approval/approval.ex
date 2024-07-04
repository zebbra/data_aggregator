defmodule DataAggregator.Records.Approval do
  @moduledoc """
  A approval represents a by infospecies approved set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Approval.Changes
  alias DataAggregator.Records.Collection

  @type t :: %Approval{}

  attributes do
    uuid_attribute :id, prefix: "app"

    attribute :file_url, :string, allow_nil?: false
    attribute :records_count, :integer, allow_nil?: true, default: 0
    attribute :records_approved, :integer, allow_nil?: true, default: 0
    attribute :started_at, :utc_datetime, allow_nil?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true

    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment do
      api DataAggregator.Files
    end

    belongs_to :job, Job do
      api DataAggregator.Jobs
      attribute_type :integer
      attribute_writable? true
      allow_nil? true
    end
  end

  calculations do
    calculate :attachment_url, :string do
      calculation fn approval, _opts -> approval.attachment.url end
      load attachment: :url
    end

    calculate :attachment_byte_size, :integer, expr(attachment.byte_size)
    calculate :attachment_filename, :string, expr(attachment.filename)
  end

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :enqueue, from: [:pending, :done, :failed], to: :queued
      transition :run, from: [:pending, :done, :failed, :queued], to: :running
      transition :set_running, from: [:pending, :done, :failed, :queued], to: :running
      transition :set_done, from: :running, to: :done
      transition :set_failed, from: :running, to: :failed
    end
  end

  preparations do
    prepare build(sort: [id: :desc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:read, :destroy, :update]

    read :by_collection do
      argument :collection_id, :string, allow_nil?: false
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 countable: true,
                 required?: false,
                 keyset?: true

      filter expr(collection_id == ^arg(:collection_id))
    end

    create :create do
      primary? true

      change Changes.SetCount
    end

    update :enqueue do
      accept []
      change transition_state(:queued)
      change Changes.EnqueueApprover
    end

    update :set_running do
      accept []
      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
    end

    update :set_failed do
      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change Collection.Changes.SetCollectionIdleAfterTransaction
    end

    update :run do
      accept []
      change Changes.SetTimeout
      change Changes.SetRunningBeforeTransaction
      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change Changes.ApproveRecords
      change Changes.SetDoneAfterAction
      change load(:attachment)
    end

    update :set_done do
      accept []
      change transition_state(:done)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change Collection.Changes.SetCollectionIdleAfterTransaction
    end

    update :update_attachment do
      accept []
      argument :attachment, Attachment, allow_nil?: false
      change manage_relationship(:attachment, :attachment, type: :append)
      change load(:attachment)
    end
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :run
    define :enqueue
    define :set_done
    define :set_running
    define :set_failed
    define :update_attachment, action: :update_attachment, args: [:attachment]
  end

  postgres do
    table "approvals"
    repo DataAggregator.Repo

    references do
      reference :attachment, on_delete: :delete, on_update: :update
      reference :job, on_delete: :nilify, on_update: :update
    end
  end

  graphql do
    type :approval

    queries do
      get :get_approval, :read
      list :list_approvals, :read
    end

    mutations do
      create :create_approval, :create
      update :update_approval, :update
      destroy :destroy_approval, :destroy
    end
  end

  json_api do
    type "approval"

    routes do
      base "/approvals"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy
    end
  end
end
