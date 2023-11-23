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

  defp detect_columns(filename) do
    Logger.debug("Detecting columns for file #{inspect(filename)} ...")

    with {:ok, df} <- Records.DataFrame.from_file(filename) do
      columns =
        df
        |> Explorer.DataFrame.dtypes()
        |> Enum.map(fn {name, type} -> %Import.Column{name: name, type: type} end)

      Logger.info("Detected #{length(columns)} in import file #{inspect(filename)}")

      {:ok, columns}
    end
  end
end
