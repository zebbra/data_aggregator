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

  actions do
    create :create do
      primary? true
      accept [:name]
    end

    update :update do
      primary? true
      accept [:mapped_to]
    end
  end
end
