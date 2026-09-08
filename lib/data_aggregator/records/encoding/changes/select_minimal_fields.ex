defmodule DataAggregator.Records.Encoding.Changes.SelectMinimalFields do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    select(changeset)
  end

  def atomic(changeset, _opts, _context) do
    {:ok, select(changeset)}
  end

  defp select(changeset) do
    Ash.Changeset.select(changeset, [
      :id,
      :collection_id,
      :record_id,
      :tax_scientific_name,
      :mte_catalog_number
    ])
  end
end
