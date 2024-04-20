defmodule Pagify.Factory.Comment do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshUUID]

  ets do
    table :comments
    private? true
  end

  attributes do
    uuid_attribute :id
    attribute :body, :string, allow_nil?: false
  end

  relationships do
    belongs_to :post, Pagify.Factory.Post do
      allow_nil? false
      api Pagify.Factory.Api
    end
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    defaults [:create]

    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
      pagination offset?: true, countable: true, required?: false
    end
  end

  code_interface do
    define_for Pagify.Factory.Api
    define :read
    define :create
  end
end
