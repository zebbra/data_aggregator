defmodule DataAggregator.Jobs.Job do
  @moduledoc """
  Ash resource for Oban jobs
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Jobs

  attributes do
    integer_primary_key :id, public?: true
    attribute :state, :atom, public?: true
    attribute :queue, :string, default: "default", public?: true
    attribute :worker, :string, public?: true

    attribute :args, :map, public?: true
    # field :meta, :map, default: %{}, public?: true
    # field :tags, {:array, :string}, default: [], public?: true
    attribute :errors, {:array, :map}, public?: true
    attribute :attempt, :integer, default: 0, public?: true
    attribute :attempted_by, {:array, :string}, public?: true
    attribute :max_attempts, :integer, public?: true

    # field :priority, :integer, public?: true

    # field :attempted_at, :utc_datetime_usec, public?: true
    # field :cancelled_at, :utc_datetime_usec, public?: true
    # field :completed_at, :utc_datetime_usec, public?: true
    # field :discarded_at, :utc_datetime_usec, public?: true
    # field :inserted_at, :utc_datetime_usec, public?: true
    # field :scheduled_at, :utc_datetime_usec, public?: true

    # field :conf, :map, virtual: true, public?: true
    # field :conflict?, :boolean, virtual: true, default: false, public?: true
    # field :replace, {:array, :any}, virtual: true, public?: true
    # field :unique, :map, virtual: true, public?: true
    # field :unsaved_error, :map, virtual: true, public?: true
  end

  actions do
    default_accept :*
    defaults [:read]
  end

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "oban_jobs"
    repo DataAggregator.Repo
    migrate? false
  end
end
