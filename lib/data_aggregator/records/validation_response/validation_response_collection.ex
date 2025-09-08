defmodule DataAggregator.Records.ValidationResponseCollection do
  @moduledoc """
  A join table resource for the many-to-many relationship between ValidationResponse and Collection
  """

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: DataAggregator.Records,
    extensions: [AshUUID]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationResponse

  relationships do
    belongs_to :validation_response, ValidationResponse do
      primary_key? true
      allow_nil? false
    end

    belongs_to :collection, Collection do
      primary_key? true
      allow_nil? false
    end
  end

  identities do
    identity :vr_coll_key, [:validation_response_id, :collection_id]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:validation_response_id, :collection_id]
      primary? true
      upsert? true
      upsert_identity :vr_coll_key
      upsert_fields []
    end
  end

  code_interface do
    define :read
    define :create
    define :destroy
    define :get_by_vr_coll, action: :read, get_by_identity: :vr_coll_key
  end

  postgres do
    table "validation_response_2_collections"
    repo DataAggregator.Repo
  end
end
