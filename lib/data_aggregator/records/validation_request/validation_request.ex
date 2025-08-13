defmodule DataAggregator.Records.ValidationRequest do
  @moduledoc """
  A Validation Request represent a set of records to be validated.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub],
    authorizers: [Ash.Policy.Authorizer]

  import DataAggregator.Checks.Custom

  alias __MODULE__
  alias DataAggregator.Accounts.User
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Changes.SetCollectionIdleAfterTransaction
  alias DataAggregator.Records.ValidationRequest.Changes

  @type t :: %ValidationRequest{}

  attributes do
    uuid_attribute :id, prefix: "vrq", public?: true

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :started_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :finished_at, :utc_datetime, allow_nil?: true, public?: true
    attribute :records_query, :map, allow_nil?: false, public?: true
    attribute :processed_rows_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :total_rows_count, :integer, allow_nil?: false, default: 0, public?: true
    attribute :center, :atom, allow_nil?: true, public?: true

    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :collection, Collection do
      public? true
      allow_nil? false
    end

    belongs_to :started_by, User, public?: true
    belongs_to :attachment, Attachment, public?: true
  end

  calculations do
    calculate :validation_request_progress,
              :float,
              expr(processed_rows_count / if(total_rows_count == 0, do: 1, else: total_rows_count))

    calculate :duration, :time, expr((finished_at || now()) - started_at)

    calculate :collection_name, :string, expr(collection.name)

    calculate :attachment_url, :string do
      calculation fn validation_request, _opts ->
        Enum.map(validation_request, & &1.attachment.url)
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
      transition :cancel_validation_request, from: [:running, :queued], to: :failed
    end

    preparations do
      prepare build(sort: [id: :desc])
      prepare DataAggregator.Preparations.Sort
    end

    actions do
      default_accept :*
      defaults [:read, :destroy, :update]

      read :active do
        filter expr(state in [:running, :queued])
      end

      create :create do
        primary? true
        argument :collection, :struct, allow_nil?: false

        change manage_relationship(:collection, type: :append)
      end

      update :enqueue do
        accept [:started_by_id]
        require_atomic? false

        change transition_state(:queued)
        change Changes.EnqueueValidationRequestHandler
      end

      update :add_validation_request_progress do
        accept []
        argument :processed_rows, :integer, allow_nil?: false

        change atomic_update(
                 :processed_rows_count,
                 expr(processed_rows_count + ^arg(:processed_rows))
               )

        change ensure_selected(:processed_rows_count)
      end

      update :set_running do
        accept []
        require_atomic? false

        change transition_state(:running)
        change set_attribute(:started_at, &DateTime.utc_now/0)
        change set_attribute(:finished_at, nil)
      end

      update :set_failed do
        require_atomic? false

        change transition_state(:failed)
        change set_attribute(:finished_at, &DateTime.utc_now/0)
        change SetCollectionIdleAfterTransaction
      end

      update :run do
        accept []
        require_atomic? false

        change Changes.SetTimeout
        change Changes.SetRunningBeforeTransaction
        change transition_state(:running)
        change set_attribute(:started_at, &DateTime.utc_now/0)
        change Changes.SendValidationRequest
        change Changes.SetFailedOnError
        change Changes.SetDoneAfterAction
        change Changes.SetCollectionIdleAfterTransaction
        change load(:attachment)
      end

      update :set_done do
        accept []
        require_atomic? false

        change transition_state(:done)
        change set_attribute(:finished_at, &DateTime.utc_now/0)
        change SetCollectionIdleAfterTransaction
      end

      update :update_attachment do
        accept []
        require_atomic? false

        argument :attachment, :struct, allow_nil?: false
        change manage_relationship(:attachment, type: :append)
        change load(:attachment)
      end

      update :cancel_validation_request do
        accept []
        require_atomic? false

        change transition_state(:failed)
        change set_attribute(:finished_at, &DateTime.utc_now/0)
      end
    end

    pub_sub do
      module DataAggregator.PubSub
      prefix "validation_request"

      publish_all :create, [[:collection_id, nil], "created"]
      publish_all :destroy, [[:collection_id, nil], "destroyed", [:id, nil]]
      publish :add_validation_request_progress, [[:collection_id, nil], "updated", [:id, nil]]
      publish :set_running, [[:collection_id, nil], "updated", [:id, nil]]
      publish :set_done, [[:collection_id, nil], "updated", [:id, nil]]
      publish :set_failed, [[:collection_id, nil], "updated", [:id, nil]]
    end

    code_interface do
      define :read
      define :active
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
      define :add_validation_request_progress, args: [:processed_rows]
      define :cancel_validation_request
    end

    policies do
      bypass with_role("admin") do
        authorize_if always()
      end

      policy action_type([:read, :update]) do
        authorize_if always()
      end

      policy action_type(:destroy) do
        authorize_if with_role("collection_administrator")
      end
    end

    postgres do
      table "validation_requests"
      repo DataAggregator.Repo

      references do
        reference :collection, on_delete: :delete, on_update: :update, index?: true
        reference :attachment, on_delete: :delete, on_update: :update, index?: true
      end
    end

    json_api do
      type "validation_requests"

      routes do
        base "/datasets/:collection_id/validation_requests"

        get :read
        index :read
        post :create
        patch :update
        delete :destroy
      end
    end

    multitenancy do
      strategy :attribute
      attribute :collection_id
    end
  end
end
