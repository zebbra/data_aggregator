defmodule DataAggregator.Records.Import.Calculations.AttachmentData do
  @moduledoc """
  This `Ash.Calculation` loads the attachment data for an `DataAggregator.Records.Import` as a `Explorer.DataFrame`.

  > ### Important {: .warning}
  >
  > Currently, this is using `Explorer.DataFrame.from_csv/2` and expects
  > the attachment to be a CSV file. In the future, we may support other formats.

  ## Arguments

  * `mapped` - If `true`, the column names will be mapped to the `mapped_to` names specified
    by the imports [`columns`](DataAggregator.Records.Import.Column) (default: `false`).

  ## Example

  ```elixir
  # Load the data with the original column names
  import = Import.get_by_id!(1, load: [:attachment_data])

  # Load the data with the mapped column names
  import = Import.get_by_id!(1, load: [attachment_data: [mapped: true]])

  # Process the data using `Explorer.DataFrame` functions
  import.attachment_data
  |> Explorer.DataFrame.head()

  ```


  """

  use Ash.Calculation

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.DataFrame
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Column

  require Logger

  @impl Ash.Calculation
  def calculate(imports, opts, ctx) do
    imports
    |> DataAggregator.Records.load!([attachment: :cached_file], lazy?: true)
    |> Enum.reverse()
    |> Enum.reduce_while([], &reduce_attachment(&1, &2, opts, ctx))
  end

  defp reduce_attachment(%Import{} = import, acc, opts, context) do
    case attachment_data(import, opts, context) do
      {:ok, data} ->
        {:cont, [data | acc]}

      {:error, error} ->
        {:halt, {:error, error}}
    end
  end

  defp attachment_data(%Import{} = import, opts, context) do
    with {:ok, data} <- create_dataframe(import, opts, context) do
      data = maybe_apply_mapping(data, import, opts, context)
      {:ok, data}
    end
  end

  defp create_dataframe(import, _opts, _context) do
    %Import{attachment: %Attachment{cached_file: cached_file}} = import

    case DataFrame.from_file(cached_file) do
      {:ok, data} ->
        {:ok, data}

      {:error, error} ->
        Logger.warning("Could not load attachment data for import #{import.id} (#{cached_file}): #{inspect(error)}")

        {:error, error}
    end
  end

  defp maybe_apply_mapping(%Explorer.DataFrame{} = data, import, _opts, %{mapped: true}) do
    %Import{columns: columns} = import

    mappings = column_mappings(columns)
    columns = Map.keys(mappings)

    data
    |> Explorer.DataFrame.select(columns)
    |> Explorer.DataFrame.rename(mappings)
  end

  defp maybe_apply_mapping(data, _import, _opts, _ctx) do
    data
  end

  defp column_mappings(nil), do: %{}

  defp column_mappings(columns) do
    mapped_columns = fn
      %Column{mapped_to: nil} ->
        []

      %Column{name: name, mapped_to: mapped_to} ->
        [{name, mapped_to}]
    end

    columns
    |> Enum.flat_map(mapped_columns)
    |> Map.new()
  end
end
