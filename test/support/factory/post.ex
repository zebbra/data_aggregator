defmodule Pagify.Factory.Post do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshUUID]

  @default_limit 15
  def default_limit, do: @default_limit

  ets do
    table :posts
    private? true
  end

  attributes do
    uuid_attribute :id
    attribute :name, :string, allow_nil?: false
    attribute :author, :string

    # allow sorting by inserted_at/updated_at
    timestamps private?: false, writable?: false
  end

  relationships do
    has_many :comments, Pagify.Factory.Comment do
      api Pagify.Factory.Api
    end
  end

  aggregates do
    count :comments_count, :comments
  end

  preparations do
    prepare build(sort: [id: :asc])
    prepare DataAggregator.Preparations.Sort
  end

  actions do
    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true
      pagination offset?: true, default_limit: @default_limit, countable: true, required?: false
    end

    create :create do
      primary? true
      argument :comments, {:array, :string}, allow_nil?: true
      change manage_relationship(:comments, type: :create, value_is_key: :body)
    end
  end

  code_interface do
    define_for Pagify.Factory.Api
    define :read
    define :create
  end
end
