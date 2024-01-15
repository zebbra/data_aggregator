defmodule DataAggregator.Jobs.Job do
  @moduledoc """
  Ash resource for Oban jobs
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    integer_primary_key :id
    attribute :state, :atom
    attribute :queue, :string, default: "default"
    attribute :worker, :string

    attribute :args, :map
    # field :meta, :map, default: %{}
    # field :tags, {:array, :string}, default: []
    attribute :errors, {:array, :map}
    attribute :attempt, :integer, default: 0
    attribute :attempted_by, {:array, :string}
    attribute :max_attempts, :integer

    # field :priority, :integer

    # field :attempted_at, :utc_datetime_usec
    # field :cancelled_at, :utc_datetime_usec
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

  actions do
    defaults [:read]
  end

  code_interface do
    define_for DataAggregator.Jobs
    define :read
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "oban_jobs"
    repo DataAggregator.Repo
    migrate? false
  end
end
