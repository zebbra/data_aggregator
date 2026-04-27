defmodule DataAggregator.Records.Import.Changes.DetectColumns do
  @moduledoc """
  Ash change to count rows from a CSV file using `Explorer.DataFrame`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Error.Changes.InvalidArgument
  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    field = Map.get(ctx, :from, :path)
    filename = Changeset.get_argument_or_attribute(changeset, field)

    case detect_columns(filename) do
      {:ok, columns} ->
        Changeset.change_attribute(changeset, :columns, columns)

      {:error, error} ->
        message = if is_exception(error), do: Exception.message(error), else: error

        message = Records.DataFrame.maybe_parse_polaris_error(message)

        exception =
          InvalidArgument.exception(
            field: field,
            message: message,
            value: filename
          )

        Changeset.add_error(changeset, exception)
    end
  end

  def column_order(filename) when is_binary(filename) do
    case Records.DataFrame.column_names(filename) do
      {:ok, names} -> names
      {:error, error} -> raise error
    end
  end

  def column_order(%Explorer.DataFrame{} = df) do
    Explorer.DataFrame.names(df)
  end

  defp detect_columns(filename) do
    Logger.debug("Detecting columns for file #{inspect(filename)} ...")

    with {:ok, ldf} <- Records.DataFrame.from_file(filename, lazy: true) do
      dtypes = Explorer.DataFrame.dtypes(ldf)

      columns =
        ldf
        |> Explorer.DataFrame.names()
        |> Enum.map(&build_column({&1, dtypes[&1]}))

      Logger.debug("Detected #{length(columns)} in import file #{inspect(filename)}")

      {:ok, columns}
    end
  end

  # map the explorer 0.8.0+ types to a type that can be used in the database
  defp build_column({name, {:f, _}}), do: build_column({name, :float})
  defp build_column({name, {:s, _}}), do: build_column({name, :integer})
  defp build_column({name, {:datetime, _}}), do: %Import.Column{name: name, type: :date}
  defp build_column({name, {:naive_datetime, _}}), do: %Import.Column{name: name, type: :date}
  defp build_column({name, type}), do: %Import.Column{name: name, type: type}
end
