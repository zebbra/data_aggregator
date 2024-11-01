defmodule DataAggregator.Records.Collection do
  @moduledoc """
  Resource representing a collection of records.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID, AshJsonApi.Resource, AshStateMachine],
    notifiers: [Ash.Notifier.PubSub],
    authorizers: [Ash.Policy.Authorizer]

  import DataAggregator.Checks.Custom

  alias __MODULE__
  alias DataAggregator.Records
  alias DataAggregator.Records.Calculations
  alias DataAggregator.Records.Collection.Changes
  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.Validations

  @type t :: %Collection{}

  attributes do
    uuid_attribute :id, prefix: "col", public?: true

    attribute :items_to_digitize, :integer, allow_nil?: false, default: 0, public?: true
    attribute :owner, :string, allow_nil?: true, public?: true

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :code, :string do
      description "an iternationally valid code to identify the collection"
      public? true
    end

    attribute :grscicoll_reference, :string do
      description "a code to identify the collection in the GrSciColl database"
      allow_nil? false
      public? true
    end

    attribute :grscicoll_institution_key, :string do
      description "the key to identify the institution in the GrSciColl database"
      allow_nil? true
      public? true
    end

    attribute :grscicoll_institution_code, :string do
      description "the code to identify the institution in the GrSciColl database"
      allow_nil? true
      public? true
    end

    attribute :grscicoll_institution_name, :string do
      description "the name of the institution in the GrSciColl database"
      allow_nil? true
      public? true
    end

    attribute :description, :string, public?: true

    attribute :gbif_dataset_key, :string do
      description "the key of the dataset (to publish) in the GBIF database"
      allow_nil? true
      public? true
    end

    attribute :import_mapping, {:array, :map}, public?: true

    attribute :records_count, :integer, allow_nil?: false, default: 0, public?: true

    attribute :type, CollectionType, allow_nil?: false, public?: true

    # allow sorting by inserted_at/updated_at
    timestamps public?: true, writable?: false
  end

  relationships do
    belongs_to :institution, DataAggregator.Platform.Institution, public?: true

    has_many :imports, DataAggregator.Records.Import, public?: true
    has_many :exports, DataAggregator.Records.Export, public?: true
    has_many :records, DataAggregator.Records.Record, public?: true
    has_many :image_uploads, DataAggregator.Records.ImageUpload, public?: true
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
              ),
              public?: true

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
    calculate :fast_track_query, :map, Calculations.FastTrackQuery
    calculate :approval_query, :map, Calculations.ApprovalQuery
    calculate :mapping, :boolean, expr(state == :mapping)
    calculate :importing, :boolean, expr(state == :importing)
    calculate :exporting, :boolean, expr(state == :exporting)
    calculate :encoding, :boolean, expr(state == :encoding)
    calculate :publishing, :boolean, expr(state == :fast_track_publishing)
    calculate :approving, :boolean, expr(state == :approving)
    calculate :deleting, :boolean, expr(state == :deleting)
    calculate :busy, :boolean, expr(state != :idle)
  end

  aggregates do
    count :imports_count, :imports

    count :records_count_not_encoded, :records do
      filter expr(
               state == :imported or
                 state == :queued or
                 state == :encoding or
                 state == :failed
             )
    end

    count :records_count_not_published, :records do
      filter expr(fast_track_status != :published)
    end

    count :records_count_not_approved, :records do
      filter expr(approval_status != :approved)
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

  state_machine do
    initial_states [:idle]
    default_initial_state :idle

    transitions do
      transition :set_mapping, from: [:idle], to: :mapping
      transition :set_importing, from: [:idle], to: :importing
      transition :set_exporting, from: [:idle], to: :exporting
      transition :set_encoding, from: [:idle], to: :encoding
      transition :set_fast_track_publishing, from: [:idle], to: :fast_track_publishing
      transition :set_approving, from: [:idle], to: :approving
      transition :set_deleting, from: [:idle], to: :deleting

      transition :set_idle,
        from: [:mapping, :importing, :exporting, :fast_track_publishing, :approving],
        to: :idle

      transition :set_idle_encoding,
        from: [:encoding],
        to: :idle
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read, :update]

    create :create do
      primary? true

      change Changes.SetGrsciCollAttributes
    end

    update :update_import_mapping do
      accept [:import_mapping]
    end

    update :touch do
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    update :register_at_gbif do
      argument :dwca_file_url, :string, allow_nil?: false
      require_atomic? false

      change Changes.RegisterAtGbif
    end

    update :set_mapping do
      accept []
      require_atomic? false

      change transition_state(:mapping)
    end

    update :set_importing do
      accept []
      require_atomic? false

      change transition_state(:importing)
    end

    update :set_exporting do
      accept []
      require_atomic? false

      change transition_state(:exporting)
    end

    update :set_encoding do
      accept []
      require_atomic? false

      change transition_state(:encoding)
      change Changes.SetEncoding
    end

    update :set_fast_track_publishing do
      accept []
      require_atomic? false

      change transition_state(:fast_track_publishing)
    end

    update :set_approving do
      accept []
      require_atomic? false

      change transition_state(:approving)
    end

    update :set_deleting do
      accept []
      require_atomic? false

      change transition_state(:deleting)
    end

    update :set_idle do
      accept []
      require_atomic? false

      change transition_state(:idle)
    end

    update :set_idle_encoding do
      accept []
      require_atomic? false

      change transition_state(:idle)
    end

    update :decrement_records_count do
      accept []

      change atomic_update(:records_count, expr(records_count - 1))
    end

    update :enqueue_encoding do
      accept []
      argument :query, :map, allow_nil?: false
      require_atomic? false

      change Changes.SetCollectionEncodingBeforeTransaction
      change Changes.EnqueueRecordsEnqueuer
    end

    update :cancel_action do
      accept []
      require_atomic? false

      change Changes.CancelAction
      change Changes.SetCollectionIdleAfterTransaction
    end

    destroy :destroy do
      accept []
      primary? true
      require_atomic? false

      change Changes.SetDeletingBeforeTransaction
    end

    action :export, :map do
      argument :export, :struct, allow_nil?: false

      run Records.Actions.ExportRecords
    end

    # starts the publication process to the SwissNatColl portal for the given query of records
    action :publish, :map do
      argument :publication, :struct, allow_nil?: false

      run Records.Actions.Publish
    end

    # starts the approval process towards infospecies for the given query of records
    action :approve, :map do
      argument :collection, :struct, allow_nil?: false
      argument :query, :map, allow_nil?: false

      run Records.Actions.Approve
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "collection"

    publish_all :create, ["created", [:id, nil]]
    publish_all :destroy, ["destroyed", [:id, nil]]
    publish :update, ["updated", [:id, nil]]

    publish :set_mapping, ["updated", [:id, nil]]
    publish :set_importing, ["updated", [:id, nil]]
    publish :set_exporting, ["updated", [:id, nil]]
    publish :set_encoding, ["updated", [:id, nil]]
    publish :set_fast_track_publishing, ["updated", [:id, nil]]
    publish :set_approving, ["updated", [:id, nil]]
    publish :set_idle, ["updated", [:id, nil]]
    publish :set_idle_encoding, ["updated", [:id, nil]]
    publish :set_deleting, ["updated", [:id, nil]]

    publish :decrement_records_count, ["updated", [:id, nil]]
  end

  code_interface do
    define :read
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :update_import_mapping, args: [:import_mapping]
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_grscicoll_reference, action: :read, get_by: [:grscicoll_reference]
    define :touch
    define :enqueue_encoding, args: [:query]
    define :export, action: :export, args: [:export]
    define :publish, args: [:publication]
    define :approve, args: [:collection, :query]
    define :register_at_gbif, args: [:dwca_file_url]

    define :set_mapping
    define :set_importing
    define :set_exporting
    define :set_encoding
    define :set_fast_track_publishing
    define :set_approving
    define :set_deleting
    define :set_idle
    define :set_idle_encoding

    define :decrement_records_count
    define :cancel_action
  end

  policies do
    bypass with_role("admin") do
      authorize_if always()
    end

    policy action(:cancel_action) do
      forbid_unless with_role("admin")
    end

    policy_group with_role("collection_digitizer") do
      policy action_type(:read) do
        authorize_if relates_to_institution_filter(:grscicoll_institution_key)
      end

      policy action([
               :set_mapping,
               :set_importing,
               :set_exporting,
               :set_encoding,
               :set_fast_track_publishing,
               :set_approving,
               :set_deleting,
               :set_idle,
               :set_idle_encoding,
               :enqueue_encoding
             ]) do
        authorize_if with_role(["admin", "data_administrator"])
      end

      policy action_type([:create, :update, :destroy]) do
        authorize_if relates_to_institution_check(:grscicoll_institution_key)
      end
    end

    policy_group with_role("data_administrator") do
      policy action_type(:read) do
        authorize_if relates_to_institution_filter(:grscicoll_institution_key)
      end

      policy action_type(:update) do
        authorize_if relates_to_institution_check(:grscicoll_institution_key)
      end

      policy action(:update) do
        authorize_if with_role("collection_digitizer")
      end
    end
  end

  validations do
    validate {Validations.GrSciCollValidator, [attribute: :grscicoll_reference, kind: :collection]} do
      on [:create]
    end
  end

  postgres do
    table "collections"
    repo DataAggregator.Repo
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

  defimpl Ash.ToTenant do
    def to_tenant(%{id: id}, _resource), do: id
  end
end
