defmodule DataAggregator.Records.Validation.Changes.RelateRecord do
  @moduledoc """
  This change relates the `DataAggregator.Records.Record` to the `DataAggregator.Records.ValidatedRecord`
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Record

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_action(changeset, &relate_record/1)
  end

  defp relate_record(%Changeset{} = changeset) do
    catalog_number = Changeset.get_attribute(changeset, :mte_catalog_number)

    with {:ok, catalog_number} <- get_catalog_number(catalog_number),
         {:ok, record} <- Record.get_by_mte_catalog_number(catalog_number) do
      Changeset.manage_relationship(
        changeset,
        :record,
        record,
        type: :append
      )
    else
      {:error, error} -> Changeset.add_error(changeset, error)
    end
  end

  defp get_catalog_number(nil), do: {:error, "mte_catalog_number is required"}

  defp get_catalog_number(mte_catalog_number), do: {:ok, mte_catalog_number}
end
