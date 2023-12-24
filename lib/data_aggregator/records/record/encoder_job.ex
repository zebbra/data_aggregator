defmodule DataAggregator.Records.Record.EncoderJob do
  @moduledoc """
  Resource representing an job attached to a `DataAggregator.Records.Record`.
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshUUID, AshGraphql.Resource, AshJsonApi.Resource]

  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Record

  attributes do
    uuid_attribute :id, prefix: "enj"
    timestamps private?: false, writable?: false
  end

  relationships do
    belongs_to :job, Job do
      api DataAggregator.Jobs
      attribute_type :integer
    end

    belongs_to :record, Record
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  code_interface do
    define_for DataAggregator.Records
    define :read
    define :create
    define :update
    define :destroy
    define :get_by_id, action: :read, get_by: [:id]
  end

  postgres do
    table "encoder_jobs"
    repo DataAggregator.Repo
  end

  graphql do
    type :encoder_job

    queries do
      get :get_encoder_job, :read
      list :list_encoder_jobs, :read
    end

    mutations do
      create :create_encoder_job, :create
      update :update_encoder_job, :update
      destroy :destroy_encoder_job, :destroy
    end
  end

  json_api do
    type "encoder_job"

    routes do
      base("/encoder_jobs")

      get(:read)
      index :read
      post(:create)
      patch(:update)
      delete(:destroy)
    end
  end
end
