defmodule DataAggregator.Data.Changes.ExtractAttributes do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  def change(%Changeset{} = changeset, _opts, _ctx) do
    params = Changeset.get_argument(changeset, :params)

    {attributes, extra_data} = extract_attributes(params)

    changeset
    |> Changeset.change_attributes(attributes)
    |> Changeset.change_attribute(:import_data, params)
    |> Changeset.change_attribute(:extra_data, extra_data)
  end

  defp extract_attributes(params) do
    Map.split(params, record_attributes())
  end

  defp record_attributes do
    DataAggregator.Data.Record
    |> Ash.Resource.Info.attributes()
    |> Enum.map(& &1.name)
    |> Enum.map(&Atom.to_string/1)
  end
end
