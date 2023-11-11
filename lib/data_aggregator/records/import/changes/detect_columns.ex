defmodule DataAggregator.Records.Changes.DetectColumns do
  @moduledoc """
  Ash change to detect columns from a CSV file using `Explorer.DataFrame`.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import.Column

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    path = Changeset.get_argument(changeset, :path)

    case detect_columns(path) do
      {:ok, columns} ->
        Changeset.change_attribute(changeset, :columns, columns)

      {:error, error} ->
        message = Exception.message(error)

        Changeset.add_error(changeset,
          field: :path,
          message: "path is invalid (#{message})",
          value: path
        )
    end
  end

  defp detect_columns(path) do
    with {:ok, df} <- Explorer.DataFrame.from_csv(path) do
      columns =
        df
        |> Explorer.DataFrame.dtypes()
        |> Enum.map(fn {name, type} -> %Column{name: name, type: type} end)

      {:ok, columns}
    end
  end
end
