defmodule DataAggregator.Records.Import.Changes.SetRecordsCountAfterTransaction do
  @moduledoc """
  Sets the records count on the `:collection` after the transaction is completed.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_transaction(changeset, &set_records_count/2)
  end

  defp set_records_count(_changeset, {:ok, import}) do
    import = Ash.load!(import, [:collection], lazy?: true, tenant: import.collection_id)

    collection = import.collection

    records_count =
      Record
      |> Ash.Query.set_tenant(collection)
      |> Ash.count!()

    Collection.update(
      collection,
      %{
        records_count: records_count
      },
      tenant: collection
    )

    {:ok, import}
  end

  defp set_records_count(_changeset, {:error, error}) do
    {:error, error}
  end
end
