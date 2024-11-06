defmodule DataAggregator.Records.Approval do
  @moduledoc """
  A approval represents a by infospecies approved set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine]

  alias __MODULE__
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Approval.Changes
  alias DataAggregator.Records.Collection

  @type t :: %Approval{}

  attributes do
    uuid_attribute :id, prefix: "app", public?: true

    attribute :file_url, :string, allow_nil?: false, public?: true

    attribute :rows_count, :integer, allow_nil?: true, public?: true
    attribute :rows_invalid_count, :integer, allow_nil?: true, public?: true
    attribute :rows_approved_count, :integer, allow_nil?: true, public?: true
    attribute :rows_error_count, :integer, allow_nil?: true, public?: true

    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment, public?: true
    belongs_to :error_log, Attachment, public?: true

    belongs_to :collection, Collection do
      public? true
      allow_nil? false
    end
  end

  calculations do
    calculate :attachment_url, :string do
      calculation fn publications, _opts ->
        Enum.map(publications, & &1.attachment.url)
      end

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
    default_accept :*
    defaults [:read, :destroy, :update]

    create :create do
      primary? true
      accept [:file_url]
      argument :collection, :struct, allow_nil?: false

      change Changes.SetCount
      change manage_relationship(:collection, type: :append)
    end

    update :enqueue do
      accept []
      require_atomic? false

      change transition_state(:queued)
      change Changes.EnqueueApprover
    end

    update :set_running do
      accept []
      require_atomic? false

      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
      change set_attribute(:rows_approved_count, 0)
      change set_attribute(:rows_invalid_count, 0)
      change set_attribute(:rows_error_count, 0)
    end

    update :set_failed do
      require_atomic? false

      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
      change Collection.Changes.SetCollectionIdleAfterTransaction
    end

    update :run do
      accept []
      require_atomic? false

      change Changes.SetTimeout
      change Changes.SetRunningBeforeTransaction
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change Changes.ApproveRecords
      change Changes.SetDoneAfterAction
      change load(:attachment)
    end

    update :set_done do
      accept []
      require_atomic? false

      change transition_state(:done)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end

    update :update_attachment do
      accept []
      require_atomic? false

      argument :attachment, :struct, allow_nil?: false
      change manage_relationship(:attachment, type: :append)
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
      argument :error_log, :struct, allow_nil?: false
      require_atomic? false

      change manage_relationship(:error_log, type: :append)
      change load(:error_log)
    end
  end

  code_interface do
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
      reference :collection, on_delete: :delete, on_update: :update
      reference :attachment, on_delete: :delete, on_update: :update, index?: true
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

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
