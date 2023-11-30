defmodule DataAggregator.Records.Import.Column do
  @moduledoc """
  Columns stored during the import of a file. Represent the schema of the csv file and the mapping to the collection's schema.
  """

  use Ash.Resource,
    data_layer: :embedded

  attributes do
    attribute :name, :string, primary_key?: true, allow_nil?: false
    attribute :type, :atom, allow_nil?: false
    attribute :mapped_to, :string, allow_nil?: true
  end

  calculations do
    calculate :mapped?, :boolean, expr(not is_nil(mapped_to))
  end

  actions do
    read :read do
      primary? true
      prepare build(load: [:mapped?])
    end

    create :create do
      primary? true
      accept [:name, :type, :mapped_to]
    end

    create :create_mapping do
      accept [:name, :mapped_to]
      require_attributes [:mapped_to]
      allow_nil_input [:type]
    end

    update :update do
      primary? true
      accept [:mapped_to]
    end

    update :update_mapping do
      accept [:name, :mapped_to]
      require_attributes [:mapped_to]
    end
  end
end
