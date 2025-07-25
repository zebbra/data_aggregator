defmodule DataAggregator.Test.User do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    domain: DataAggregator.Test.DummyDomain,
    extensions: [AshUUID]

  alias DataAggregator.Files.Attachment

  ets do
    table :files_dummy
    private? true
  end

  attributes do
    uuid_attribute :id, prefix: "fat", public?: true
    attribute :name, :string, allow_nil?: false, public?: true
  end

  relationships do
    belongs_to :avatar, Attachment, public?: true
  end

  actions do
    default_accept :*

    create :with_avatar do
      argument :avatar_path, :string, allow_nil?: false
      change manage_relationship(:avatar_path, :avatar, value_is_key: :path, type: :create)
    end
  end
end
