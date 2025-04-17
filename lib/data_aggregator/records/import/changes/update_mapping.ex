defmodule DataAggregator.Records.Import.Changes.UpdateMapping do
  @moduledoc """
  Changeset hook to update the mapping of columns to the collection's schema.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import.Column

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    case Changeset.fetch_change(changeset, :columns) do
      :error ->
        changeset

      {:ok, mappings} ->
        columns =
          changeset
          |> get_columns()
          |> merge_mappings(mappings)

        changeset
        |> Changeset.change_attribute(:columns, columns)
        |> Changeset.after_action(&save_mappings_to_collection/2)
    end
  end

  # get the columns from the already present `data` or the changed `attributes`
  defp get_columns(changeset) do
    columns = Changeset.get_data(changeset, :columns)

    if columns == nil do
      Changeset.get_attribute(changeset, :columns)
    else
      columns
    end
  end

  defp save_mappings_to_collection(_changeset, import) do
    # update mapping on collection as well, so we can reuse it on future imports

    import = Ash.load!(import, [:collection])

    columns = import.columns
    collection = import.collection

    Collection.update_import_mapping!(
      collection,
      Enum.map(columns, fn column ->
        %{name: column.name, mapped_to: column.mapped_to, type: column.type}
      end)
    )

    {:ok, import}
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
