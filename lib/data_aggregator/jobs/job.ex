defmodule DataAggregator.Jobs.Job do
  @moduledoc """
  Ash resource for Oban jobs
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Jobs

  attributes do
    integer_primary_key :id, public?: true
    attribute :state, DataAggregator.Jobs.Types.ObanJobState, public?: true
    attribute :queue, :string, default: "default", public?: true
    attribute :worker, :string, public?: true

    attribute :args, :map, public?: true
    # field :meta, :map, default: %{}
    # field :tags, {:array, :string}, default: []
    attribute :errors, {:array, :map}, public?: true
    attribute :attempt, :integer, default: 0, public?: true
    attribute :attempted_by, {:array, :string}, public?: true
    attribute :max_attempts, :integer, public?: true

    # field :priority, :integer

    # field :attempted_at, :utc_datetime_usec
    attribute :cancelled_at, :utc_datetime_usec, public?: true
    # field :completed_at, :utc_datetime_usec
    # field :discarded_at, :utc_datetime_usec
    # field :inserted_at, :utc_datetime_usec
    # field :scheduled_at, :utc_datetime_usec

    # field :conf, :map, virtual: true
    # field :conflict?, :boolean, virtual: true, default: false
    # field :replace, {:array, :any}, virtual: true
    # field :unique, :map, virtual: true
    # field :unsaved_error, :map, virtual: true
  end

  calculations do
    calculate :collection_id, :string, expr(args[:collection_id])
  end

  actions do
    default_accept :*
    defaults [:read, :update]

    read :imports_by_collection do
      argument :collection_id, :string, allow_nil?: false

      filter expr(collection_id == ^arg(:collection_id) and queue == "imports")
    end

    read :exports_by_collection do
      argument :collection_id, :string, allow_nil?: false

      filter expr(collection_id == ^arg(:collection_id) and queue == "exports")
    end

    read :publications_by_collection do
      argument :collection_id, :string, allow_nil?: false

      filter expr(collection_id == ^arg(:collection_id) and queue == "publications")
    end

    read :publication_verifications_by_collection do
      argument :collection_id, :string, allow_nil?: false

      filter expr(collection_id == ^arg(:collection_id) and queue == "publication_verifications")
    end

    read :encodings_by_collection do
      argument :collection_id, :string, allow_nil?: false

      filter expr(collection_id == ^arg(:collection_id) and queue == "encoders")
    end
  end

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :imports_by_collection, args: [:collection_id]
    define :exports_by_collection, args: [:collection_id]
    define :publications_by_collection, args: [:collection_id]
    define :publication_verifications_by_collection, args: [:collection_id]
    define :encodings_by_collection, args: [:collection_id]
    define :update
  end

  postgres do
    table "oban_jobs"
    repo DataAggregator.Repo
    migrate? false
  end
end
