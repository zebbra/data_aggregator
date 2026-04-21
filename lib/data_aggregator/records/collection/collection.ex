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
  alias DataAggregator.Records.Calculations
  alias DataAggregator.Records.Collection.Actions
  alias DataAggregator.Records.Collection.Changes
  alias DataAggregator.Records.CollectionType
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponseCollection
  alias DataAggregator.Records.Validations

  @type t :: %Collection{}

  @dataset_actions [
    :set_mapping,
    :set_importing,
    :set_exporting,
    :set_encoding,
    :set_validating,
    :set_deleting,
    :set_idle,
    :set_idle_encoding,
    :enqueue_encoding,
    :start_validations,
    :export
  ]

  attributes do
    uuid_attribute :id, prefix: "set", public?: true

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

    attribute :gbif_doi, :string do
      description "the DOI of the dataset in the GBIF database"
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
    has_many :imports, DataAggregator.Records.Import, public?: true
    has_many :exports, DataAggregator.Records.Export, public?: true
    has_many :records, DataAggregator.Records.Record, public?: true
    has_many :image_uploads, DataAggregator.Records.ImageUpload, public?: true
    has_many :validation_requests, DataAggregator.Records.ValidationRequest, public?: true
    has_many :publications, DataAggregator.Records.Publication, public?: true

    many_to_many :validation_responses, ValidationResponse do
      through ValidationResponseCollection
      source_attribute_on_join_resource :collection_id
      destination_attribute_on_join_resource :validation_response_id
      public? true
    end
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

    calculate :records_to_export_query, :map, Calculations.RecordsToExport
    calculate :publication_query, :map, Calculations.PublicationQuery
    calculate :validation_query, :map, Calculations.ValidationQuery
    calculate :mapping, :boolean, expr(state == :mapping)
    calculate :importing, :boolean, expr(state == :importing)
    calculate :exporting, :boolean, expr(state == :exporting)
    calculate :encoding, :boolean, expr(state == :encoding)
    calculate :publishing, :boolean, expr(state == :publishing)
    calculate :validating, :boolean, expr(state == :validating)
    calculate :deleting, :boolean, expr(state == :deleting)
    calculate :busy, :boolean, expr(state != :idle)
  end

  state_machine do
    initial_states [:idle]
    default_initial_state :idle

    transitions do
      transition :set_mapping, from: [:idle], to: :mapping
      transition :set_importing, from: [:idle], to: :importing
      transition :set_exporting, from: [:idle], to: :exporting
      transition :set_encoding, from: [:idle], to: :encoding
      transition :set_publishing, from: [:idle], to: :publishing
      transition :set_validating, from: [:idle, :publishing, :queued], to: :validating
      transition :set_deleting, from: [:idle], to: :deleting

      transition :set_idle,
        from: [:mapping, :importing, :exporting, :publishing, :validating],
        to: :idle

      transition :set_idle_encoding,
        from: [:encoding],
        to: :idle
    end
  end

  preparations do
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    default_accept :*
    defaults [:read, :update]

    read :list do
      prepare build(sort: [id: :asc])
    end

    create :create do
      primary? true

      change Changes.SetGrsciCollAttributes
    end

    update :update_import_mapping do
      accept [:import_mapping]
      require_atomic? false
    end

    update :touch do
      change set_attribute(:updated_at, &DateTime.utc_now/0)
    end

    update :register_at_gbif do
      argument :existing_dataset_key, :string, allow_nil?: true
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

    update :set_publishing do
      accept []
      require_atomic? false

      change transition_state(:publishing)
    end

    update :set_validating do
      accept []
      require_atomic? false

      change transition_state(:validating)
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
      primary? true
      require_atomic? false
      change Changes.SetDeleting

      change Changes.BulkSoftDeleteAttachments
    end

    action :create_endpoint, :map do
      argument :collection, :struct, allow_nil?: false
      argument :dwca_file_url, :string, allow_nil?: false

      run Actions.CreateEndpoint
    end

    action :export, :map do
      argument :export, :struct, allow_nil?: false

      run Actions.ExportRecords
    end

    # starts the publication process to the SwissNatColl portal for the given query of records
    action :publish, :map do
      argument :publication, :struct, allow_nil?: false

      run Actions.Publish
    end

    # starts the validation process towards infospecies for the given query of records
    action :validate, :map do
      argument :validation_request, :struct, allow_nil?: false

      run Actions.Validate
    end

    # creates the validation request resources and enqueues it to the validation request queue
    action :start_validations, :map do
      argument :collection, :struct, allow_nil?: false

      run Actions.StartValidations
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
    publish :set_publishing, ["updated", [:id, nil]]
    publish :set_validating, ["updated", [:id, nil]]
    publish :set_idle, ["updated", [:id, nil]]
    publish :set_idle_encoding, ["updated", [:id, nil]]
    publish :set_deleting, ["updated", [:id, nil]]

    publish :decrement_records_count, ["updated", [:id, nil]]
  end

  code_interface do
    define :read
    define :list
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :update_import_mapping, args: [:import_mapping]
    define :destroy, action: :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_grscicoll_reference, action: :read, get_by: [:grscicoll_reference]
    define :get_by_code, action: :read, get_by: [:code]
    define :touch
    define :enqueue_encoding, args: [:query]
    define :create_endpoint, args: [:collection, :dwca_file_url]
    define :export, action: :export, args: [:export]
    define :publish, args: [:publication]
    define :validate, args: [:validation_request]
    define :start_validations, args: [:collection]
    define :register_at_gbif, args: [:existing_dataset_key]

    define :set_mapping
    define :set_importing
    define :set_exporting
    define :set_encoding
    define :set_publishing
    define :set_validating
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

    policy action([:cancel_action, :destroy]) do
      forbid_unless with_role("admin")
    end

    policy_group with_role(["collection_administrator", "data_digitizer"]) do
      policy action_type(:read) do
        authorize_if relates_to_institution_filter(:grscicoll_institution_key)
      end
    end

    policy_group with_role("collection_administrator") do
      policy action_type([:create, :update]) do
        authorize_if relates_to_institution_check(:grscicoll_institution_key)
      end

      policy action(@dataset_actions) do
        forbid_unless with_role(["admin", "data_digitizer"])
        authorize_if relates_to_institution_check(:grscicoll_institution_key)
      end

      policy action([:publish, :set_publishing]) do
        authorize_if always()
      end
    end

    policy_group with_role("data_digitizer") do
      policy action(@dataset_actions) do
        authorize_if relates_to_institution_check(:grscicoll_institution_key)
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
      base "/datasets"

      get :read
      index :list
      post :create
      patch :update
      delete :destroy
    end
  end

  defimpl Ash.ToTenant do
    def to_tenant(%{id: id}, _resource), do: id
  end
end
