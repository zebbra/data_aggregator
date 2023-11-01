defmodule DataAggregator.Platform.Changes.UpdateMapping do
  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Platform.ImportFile.Column

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    columns = Changeset.get_data(changeset, :columns)
    mappings = Changeset.get_attribute(changeset, :columns)

    columns = merge_mappings(columns, mappings)
    Changeset.change_attribute(changeset, :columns, columns)
  end

  def merge_mappings(columns, mappings) do
    columns |> Enum.map(&merge_mapping(&1, mappings))
  end

  def merge_mapping(%Column{name: name} = column, mappings) do
    case get_column(mappings, name) do
      %Column{mapped_to: mapped_to} -> %{column | mapped_to: mapped_to}
      nil -> column
    end
  end

  def get_column(columns, name) do
    Enum.find(columns, &(&1.name == name))
  end
end
