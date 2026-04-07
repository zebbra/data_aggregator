defmodule DataAggregator.Records.ValidationRequestRecord do
  @moduledoc false

  use Ash.Resource,
    otp_app: :data_aggregator,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshPaperTrail.Resource],
    authorizers: [Ash.Policy.Authorizer],
    domain: DataAggregator.Records

  alias __MODULE__
  alias DataAggregator.Checks

  @type t :: %ValidationRequestRecord{}

  attributes do
    uuid_attribute :id, prefix: "vrr", public?: true

    attribute :data, :map, allow_nil?: false, public?: true

    timestamps()
  end

  paper_trail do
    mixin DataAggregator.Records.ValidationRequestRecordMixin
    attributes_as_attributes [:collection_id]

    reference_source? true

    ignore_attributes [
      :inserted_at,
      :updated_at
    ]

    ignore_actions [:destroy]

    belongs_to_actor :user, DataAggregator.Accounts.User,
      domain: DataAggregator.Accounts,
      define_attribute?: false,
      public?: true
  end

  relationships do
    belongs_to :record, DataAggregator.Records.Record do
      public? true
      allow_nil? false
    end

    belongs_to :collection, DataAggregator.Records.Collection do
      public? true
      allow_nil? false
    end
  end

  actions do
    defaults [:read, :destroy, update: :*]
    default_accept :*

    create :create do
      primary? true
      argument :collection, :struct, allow_nil?: false
      argument :record, :struct, allow_nil?: false

      change manage_relationship(:collection, type: :append)
      change manage_relationship(:record, type: :append)
    end

    create :bulk_upsert do
      accept [:data, :record_id]

      upsert? true
      upsert_identity :by_record
      upsert_fields [:data, :updated_at]
    end
  end

  identities do
    identity :by_record, [:record_id]
    identity :by_collection, [:id, :collection_id]
  end

  code_interface do
    define :create
    define :read
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_record, action: :read, get_by: [:record_id]
  end

  policies do
    bypass Checks.Custom.with_role("admin") do
      authorize_if always()
    end

    policy action_type([:read, :update]) do
      authorize_if always()
    end

    policy action_type(:destroy) do
      authorize_if Checks.Custom.with_role("collection_administrator")
    end
  end

  postgres do
    table "validation_request_records"
    repo DataAggregator.Repo

    references do
      reference :record,
        on_delete: :delete,
        on_update: :update,
        index?: true,
        match_with: [collection_id: :collection_id]

      reference :collection, on_delete: :delete, on_update: :update, index?: true
    end
  end

  multitenancy do
    strategy :attribute
    attribute :collection_id
  end
end
