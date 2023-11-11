defmodule DataAggregator.Records.Record.Changes.ExtractAttributes do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  def batch_change(changesets, opts, ctx) do
    Enum.map(changesets, &change(&1, opts, ctx))
  end

  def change(%Changeset{} = changeset, _opts, _ctx) do
    params = Changeset.get_argument(changeset, :params)

    {attributes, extra_data} = extract_attributes(params)

    changeset
    |> Changeset.change_attributes(attributes)
    |> Changeset.change_attribute(:import_data, params)
    |> Changeset.change_attribute(:extra_data, extra_data)
  end

  defp extract_attributes(nil), do: {%{}, nil}

  defp extract_attributes(params) do
    params
    |> stringify_keys()
    |> Map.split(record_attributes())
  end

  defp stringify_keys(map) do
    for {k, v} <- map, into: %{} do
      {stringify(k), v}
    end
  end

  defp record_attributes do
    for %{name: name} <- DataAggregator.DarwinCore.Schema.prefixed_attributes() do
      stringify(name)
    end
  end

  defp stringify(val) when is_atom(val), do: Atom.to_string(val)
  defp stringify(val) when is_binary(val), do: val
end
