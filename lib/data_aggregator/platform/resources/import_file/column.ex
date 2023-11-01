defmodule DataAggregator.Platform.ImportFile.Column do
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
      accept [:name, :type]
    end

    update :update do
      primary? true
      accept [:mapped_to]
    end
  end
end
