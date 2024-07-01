defmodule Pagify.Factory.Post do
  @moduledoc false
  use Ash.Resource,
    data_layer: Ash.DataLayer.Ets,
    domain: Pagify.Factory.Domain,
    extensions: [AshUUID]

  @default_limit 15
  def default_limit, do: @default_limit

  @pagify_scopes %{
    role: [
      %{name: :admin, filter: %{author: "John"}},
      %{name: :user, filter: %{author: "Doe"}}
    ],
    status: [
      %{name: :all, filter: nil, default?: true},
      %{name: :active, filter: %{age: %{lt: 10}}},
      %{name: :inactive, filter: %{age: %{gte: 10}}}
    ]
  }
  def pagify_scopes, do: @pagify_scopes

  ets do
    private? true
  end

  attributes do
    uuid_attribute :id, public?: true
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :title, :string, public?: true
    attribute :text, :string, public?: true
    attribute :author, :string, public?: true
    attribute :age, :integer, public?: true

    # allow sorting by inserted_at/updated_at
    timestamps public?: true, writable?: false
  end

  relationships do
    has_many :comments, Pagify.Factory.Comment, public?: true
  end

  aggregates do
    count :comments_count, :comments, public?: true
  end

  preparations do
    prepare build(sort: [name: :asc])
    prepare Pagify.Factory.Preparations.Sort
  end

  actions do
    default_accept :*

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
    define :read
    define :create
  end
end
