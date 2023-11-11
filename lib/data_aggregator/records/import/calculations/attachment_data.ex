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

  require Logger

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Column

  @impl Ash.Calculation
  def calculate(imports, opts, ctx) do
    imports
    |> DataAggregator.Records.load!([attachment: :url], lazy?: true)
    |> Enum.map(&attachment_data(&1, opts, ctx))
  end

  defp attachment_data(%Import{} = import, opts, context) do
    import
    |> create_dataframe(opts, context)
    |> maybe_apply_mapping(import, opts, context)
  end

  defp create_dataframe(import, _opts, _context) do
    %Import{attachment: %Attachment{url: url}} = import

    case Explorer.DataFrame.from_csv(url) do
      {:ok, data} ->
        data

      {:error, error} ->
        "Could not load attachment data for import #{import.id} (#{url}): #{inspect(error)}"
        |> Logger.warning()

        nil
    end
  end

  defp maybe_apply_mapping(%Explorer.DataFrame{} = data, import, _opts, %{mapped: true}) do
    %Import{columns: columns} = import
    mappings = column_mappings(columns)

    data |> Explorer.DataFrame.rename(mappings)
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
    |> Enum.into(%{})
  end
end
