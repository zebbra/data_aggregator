defmodule DataAggregator.Data.Changes.ImportRecords do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Data.Resources.TypeCaster

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    changing_attributes =
      changeset
      |> get_columns
      |> get_changing_attributes

    changeset
    |> change_attributes(changing_attributes)
  end

  defp change_attributes(changeset, attributes) do
    Changeset.change_attributes(changeset, attributes)
  end

  defp get_changing_attributes(columns) do
    record = %{}

    columns
    |> set_attributes(record)
  end

  def set_attributes(columns, record) when is_map(record) and is_list(columns) do
    Enum.reduce(columns, record, fn %{mapped_to: field, value: val, type: type}, acc ->
      Map.put(acc, field, cast_type(val, type))
    end)
  end

  defp cast_type(value, type) do
    TypeCaster.cast(value, type)
  end

  defp get_columns(changeset) do
    Changeset.get_argument(changeset, :columns)
  end
end
