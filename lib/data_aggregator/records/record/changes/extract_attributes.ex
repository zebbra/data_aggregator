defmodule DataAggregator.Records.Record.Changes.ExtractAttributes do
  @moduledoc """
  This change imports records from a %Column{} struct
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record.ExtractAttributesHelpers

  def batch_change(changesets, opts, ctx) do
    Enum.map(changesets, &change(&1, opts, ctx))
  end

  def change(%Changeset{} = changeset, _opts, _ctx) do
    params = Changeset.get_argument(changeset, :params)

    {attributes, extra_data} = ExtractAttributesHelpers.extract_attributes(params)

    changeset
    |> Changeset.change_attributes(attributes)
    |> Changeset.change_attribute(:import_data, params)
    |> Changeset.change_attribute(:extra_data, extra_data)
  end
end
