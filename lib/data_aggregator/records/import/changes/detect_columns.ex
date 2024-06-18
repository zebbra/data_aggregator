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

  def change(%Changeset{} = changeset, _opts, ctx) do
    field = Map.get(ctx, :from, :path)
    filename = Changeset.get_argument_or_attribute(changeset, field)

    case detect_columns(filename) do
      {:ok, columns} ->
        Changeset.change_attribute(changeset, :columns, columns)

      {:error, error} ->
        message = if is_exception(error), do: Exception.message(error), else: error

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
    with {:ok, df} <- Records.DataFrame.from_file(filename) do
      Explorer.DataFrame.names(df)
    end
  end

  def column_order(%Explorer.DataFrame{} = df) do
    Explorer.DataFrame.names(df)
  end

  defp detect_columns(filename) do
    Logger.debug("Detecting columns for file #{inspect(filename)} ...")

    with {:ok, df} <- Records.DataFrame.from_file(filename) do
      order = column_order(df)

      columns =
        df
        |> Explorer.DataFrame.dtypes()
        |> Enum.map(&build_column/1)
        |> sort_columns(order)

      Logger.debug("Detected #{length(columns)} in import file #{inspect(filename)}")

      {:ok, columns}
    end
  end

  # map the explorer 0.8.0+ types to a type that can be used in the database
  defp build_column({name, {:f, _}}), do: build_column({name, :float})
  defp build_column({name, {:s, _}}), do: build_column({name, :integer})
  defp build_column({name, {:datetime, _}}), do: %Import.Column{name: name, type: :date}
  defp build_column({name, type}), do: %Import.Column{name: name, type: type}

  defp sort_columns(columns, order) do
    Enum.map(order, fn name -> Enum.find(columns, &(&1.name == name)) end)
  end
end
