defmodule DataAggregator.Records.ValidationResponse.Changes.SetCount do
  @moduledoc """
  Sets the rows_count of the ValidationResponse object according to the rows count in the provided file
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Error.Changes.InvalidArgument
  alias DataAggregator.Records

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, ctx) do
    field = Map.get(ctx, :from, :path)
    filename = Changeset.get_argument_or_attribute(changeset, field)

    Records.DataFrame.from_file(filename)

    case count_rows(filename) do
      {:ok, rows_count} ->
        Changeset.change_attribute(changeset, :rows_count, rows_count)

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

  defp count_rows(filename) do
    Logger.debug("Counting rows for file #{inspect(filename)} ...")

    with {:ok, df} <- Explorer.DataFrame.from_csv(filename) do
      rows_count = Explorer.DataFrame.n_rows(df)

      Logger.debug("Detected #{rows_count} in import file #{inspect(filename)}")

      {:ok, rows_count}
    end
  end
end
