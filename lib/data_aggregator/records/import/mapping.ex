defmodule DataAggregator.Records.Import.Mapping do
  @moduledoc """
  Helper module to map import data from mappings defined in `DataAggregator.Records.Import.Column`.
  """

  alias DataAggregator.Records.Import.Column

  @doc """
  Maps the keys of a map of params to the mapped_to value of the column if it exists.
  """
  def map_params(params, columns) do
    for {name, value} <- params, into: %{} do
      {map_param_name(columns, name), value}
    end
  end

  defp map_param_name(columns, name) do
    columns
    |> get_column(name)
    |> get_column_mapping(name)
    |> stringify()
  end

  defp get_column_mapping(nil, default), do: default
  defp get_column_mapping(%Column{mapped_to: nil}, default), do: default
  defp get_column_mapping(%Column{mapped_to: mapped_to}, _default), do: mapped_to

  defp stringify(nil), do: nil
  defp stringify(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify(key) when is_binary(key), do: key

  defp get_column(columns, name) do
    Enum.find(columns, &(stringify(&1.name) == stringify(name)))
  end
end
