defmodule DataAggregator.Data.Resources.RecordImporter do
  @moduledoc """
  Imports records from a file stored in an Import on an existing collection.
  """

  require Explorer.DataFrame

  alias DataAggregator.Data.Record
  alias DataAggregator.Platform.Import
  alias DataAggregator.Platform.Import.Column
  alias Explorer.DataFrame

  def import_records(%Import{} = import, columns) do
    import |> read_file |> process_records(columns)
  end

  defp read_file(import) do
    import.attachment.url
    |> DataFrame.from_csv()
  end

  defp process_records(rows, columns) do
    case rows do
      {:ok, df} ->
        df
        |> DataFrame.to_rows_stream(atom_keys: true, chunk_size: 10)
        |> Enum.map(fn row -> process_record(row, columns) end)

      {:error, error} ->
        raise "Unable to process records: #{inspect(error)}"
    end
  end

  defp process_record(%{} = row, columns) do
    row
    |> map_values_to_columns(columns)
    |> Record.create_from_columns()
  end

  defp map_values_to_columns(row, columns) do
    Enum.map(row, fn {name, value} ->
      name = to_string(name)

      %Column{
        name: name,
        value: value,
        mapped_to: get_mapping_from_columns(name, columns),
        type: get_type_from_columns(name, columns)
      }
    end)
  end

  defp get_mapping_from_columns(name, columns) do
    column = find_column_by_name(name, columns)
    Map.get(column, :mapped_to, nil)
  end

  defp get_type_from_columns(name, columns) do
    column = find_column_by_name(name, columns)

    case Map.get(column, :type, nil) do
      nil -> nil
      type -> String.to_existing_atom(type)
    end
  end

  defp find_column_by_name(name, columns) do
    Enum.find(columns, fn column -> column.name == name end)
  end
end
