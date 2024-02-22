defmodule DataAggregator.Records.Import.Changes.UpdateMapping do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import.Column

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    case Changeset.fetch_change(changeset, :columns) do
      :error ->
        changeset

      {:ok, mappings} ->
        columns = changeset |> Changeset.get_data(:columns) |> merge_mappings(mappings)

        save_mappings_to_collection(changeset, columns)

        Changeset.change_attribute(changeset, :columns, columns)
    end
  end

  defp save_mappings_to_collection(changeset, columns) do
    # update mapping on collection as well, so we can reuse it on future imports
    collection = Changeset.get_data(changeset, :collection)

    Collection.update_import_mapping!(
      collection,
      Enum.map(columns, fn column ->
        %{name: column.name, mapped_to: column.mapped_to, type: column.type}
      end)
    )
  end

  defp merge_mappings(columns, mappings) do
    Enum.map(columns, &merge_mapping(&1, mappings))
  end

  defp merge_mapping(%Column{name: name} = column, mappings) do
    case get_column_mapping(mappings, name) do
      %Column{mapped_to: mapped_to} -> %{column | mapped_to: mapped_to}
      nil -> %{column | mapped_to: nil}
    end
  end

  defp get_column_mapping(mappings, name) do
    Enum.find(mappings, &(&1.name == name))
  end
end
