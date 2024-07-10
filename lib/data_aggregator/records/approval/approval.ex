defmodule DataAggregator.Records.Approval do
  @moduledoc """
  A approval represents a by infospecies approved set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource, AshStateMachine]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Approval.Changes
  alias DataAggregator.Records.Collection

  @type t :: %Approval{}

  attributes do
    uuid_attribute :id, prefix: "app"

    attribute :file_url, :string, allow_nil?: false

    attribute :rows_count, :integer, allow_nil?: true
    attribute :rows_invalid_count, :integer, allow_nil?: true
    attribute :rows_approved_count, :integer, allow_nil?: true
    attribute :rows_error_count, :integer, allow_nil?: true

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

    belongs_to :error_log, Attachment do
      api DataAggregator.Files
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

    create :create do
      accept [:file_url]
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
      change set_attribute(:rows_approved_count, 0)
      change set_attribute(:rows_invalid_count, 0)
      change set_attribute(:rows_error_count, 0)
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
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change Changes.ApproveRecords
      change Changes.SetDoneAfterAction
      change load(:attachment)
    end

    update :set_done do
      accept []
      change transition_state(:done)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end

    update :update_attachment do
      accept []
      argument :attachment, Attachment, allow_nil?: false
      change manage_relationship(:attachment, :attachment, type: :append)
      change load(:attachment)
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

    update :add_approval_progress do
      accept []

      argument :approved, :integer, allow_nil?: false
      argument :invalid, :integer, allow_nil?: false

      change atomic_update(:rows_approved_count, expr(rows_approved_count + ^arg(:approved)))
      change atomic_update(:rows_invalid_count, expr(rows_invalid_count + ^arg(:invalid)))

      change ensure_selected(:rows_approved_count)
      change ensure_selected(:rows_invalid_count)
    end

    update :update_error_log do
      accept []
      argument :error_log, Attachment, allow_nil?: false
      change manage_relationship(:error_log, :error_log, type: :append)
      change load(:error_log)
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
    define :add_approval_progress, args: [:approved, :invalid]
    define :update_error_log, args: [:error_log]
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

      patch :enqueue, route: "/:id/enqueue"
    end
  end
end
