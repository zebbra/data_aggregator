defmodule DataAggregator.Records.ValidationResponse do
  @moduledoc """
  A ValidationResponse represents a by infospecies validated set of records
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine]

  alias __MODULE__
  alias DataAggregator.Accounts.User
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationResponse.Changes
  alias DataAggregator.Records.ValidationResponseCollection
  alias DataAggregator.Records.ValidationResponseType

  @type t :: %ValidationResponse{}

  attributes do
    uuid_attribute :id, prefix: "app", public?: true

    attribute :type, ValidationResponseType, allow_nil?: false, public?: true, default: :validated

    attribute :rows_count, :integer, allow_nil?: true, public?: true
    attribute :rows_invalid_count, :integer, allow_nil?: true, public?: true
    attribute :rows_validated_count, :integer, allow_nil?: true, public?: true
    attribute :rows_error_count, :integer, allow_nil?: true, public?: true

    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :attachment, Attachment, public?: true
    belongs_to :error_log, Attachment, public?: true
    belongs_to :created_by, User, public?: true
    belongs_to :started_by, User, public?: true

    many_to_many :affected_collections, Collection do
      through ValidationResponseCollection
      source_attribute_on_join_resource :validation_response_id
      destination_attribute_on_join_resource :collection_id
      public? true
    end
  end

  calculations do
    calculate :attachment_url, :string do
      calculation fn publications, _opts ->
        Enum.map(publications, & &1.attachment.url)
      end

      load attachment: :url
    end

    calculate :duration, :time, expr((finished_at || now()) - started_at)

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

    update :add_affected_collection do
      require_atomic? false
      accept []
      argument :collection, :struct, allow_nil?: false

      change Changes.AddAffectedCollection

      change load(:affected_collections)
    end

    create :create do
      primary? true
      accept [:type]
    end

    create :create_from_path do
      accept [:created_by_id, :type]
      argument :path, :string, allow_nil?: false
      argument :filename, :string, allow_nil?: true
      change Changes.CreateAttachment
      change Changes.SetCount
      change load([:attachment_filename, :attachment_byte_size])
    end

    update :enqueue do
      accept [:started_by_id]
      require_atomic? false

      change transition_state(:queued)
      change Changes.EnqueueValidationResponseHandler
    end

    update :set_running do
      accept []
      require_atomic? false

      change transition_state(:running)
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change set_attribute(:finished_at, nil)
      change set_attribute(:rows_validated_count, 0)
      change set_attribute(:rows_invalid_count, 0)
      change set_attribute(:rows_error_count, 0)
    end

    update :set_failed do
      require_atomic? false

      change transition_state(:failed)
      change set_attribute(:finished_at, &DateTime.utc_now/0)
    end

    update :run do
      accept []
      require_atomic? false

      change load(:attachment)
      change Changes.SetTimeout
      change Changes.SetRunningBeforeTransaction
      change set_attribute(:started_at, &DateTime.utc_now/0)
      change Changes.ValidateRecords
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

      argument :validated, :integer, allow_nil?: false
      argument :invalid, :integer, allow_nil?: false

      change atomic_update(:rows_validated_count, expr(rows_validated_count + ^arg(:validated)))
      change atomic_update(:rows_invalid_count, expr(rows_invalid_count + ^arg(:invalid)))

      change ensure_selected(:rows_validated_count)
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
    define :update_attachment, args: [:attachment]
    define :add_validation_progress, args: [:validated, :invalid]
    define :update_error_log, args: [:error_log]
    define :add_affected_collection, args: [:collection]
    define :create_from_path, args: [:path, :filename]
  end

  postgres do
    table "validation_responses"
    repo DataAggregator.Repo
  end

  json_api do
    type "validation_responses"

    routes do
      base "/validation_responses"

      get :read
      index :read
      post :create
      patch :update
      delete :destroy

      patch :enqueue, route: "/:id/enqueue"
    end
  end
end
