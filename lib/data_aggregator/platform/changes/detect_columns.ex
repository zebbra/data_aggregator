defmodule DataAggregator.Platform.Changes.DetectColumns do
  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)

    case detect_columns(path) do
      {:ok, columns} ->
        Changeset.change_attribute(changeset, :columns, columns)

      {:error, error} ->
        Changeset.add_error(changeset,
          field: :path,
          message: "path is invalid, duet to error: #{inspect(error)}",
          value: path
        )
    end
  end

  defp detect_columns(path) do
    case Explorer.DataFrame.from_csv(path) do
      {:ok, df} ->
        columns =
          df
          |> Explorer.DataFrame.dtypes()
          |> Map.keys()

        {:ok, columns}

      {:error, error} ->
        Logger.error("Unable to detect columns: #{inspect(error)}")
        {:error, error}
    end
  end
end
