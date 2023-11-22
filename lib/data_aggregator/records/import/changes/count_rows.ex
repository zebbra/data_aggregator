defmodule DataAggregator.Records.Import.Changes.CountRows do
  @moduledoc """
  Ash change to detect number of rows from a CSV file using `Explorer.DataFrame`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Error.Changes.InvalidArgument
  alias DataAggregator.Records.Import

  require Logger

  def change(%Changeset{} = changeset, _opts, ctx) do
    field = Map.get(ctx, :from, :path)
    filename = Changeset.get_argument_or_attribute(changeset, field)

    case count_rows(filename) do
      {:ok, rows_count} ->
        Changeset.change_attribute(changeset, :rows_count, rows_count)

      {:error, error} ->
        message = Exception.message(error)

        exception =
          InvalidArgument.exception(
            field: field,
            message: message,
            value: filename
          )

        changeset |> Changeset.add_error(exception)
    end
  end

  defp count_rows(filename) do
    Logger.debug("Counting rows for file #{inspect(filename)} ...")

    with {:ok, df} <- Import.DataFrame.from_file(filename) do
      rows_count = df |> Explorer.DataFrame.n_rows()

      Logger.info("Detected #{rows_count} in import file #{inspect(filename)}")

      {:ok, rows_count}
    end
  end
end
