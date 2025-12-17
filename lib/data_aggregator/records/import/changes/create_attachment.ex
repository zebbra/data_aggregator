defmodule DataAggregator.Records.Import.Changes.CreateAttachment do
  @moduledoc """
  `Ash.Resource.Change` to create an import attachment.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Collection

  @impl true
  def change(%Changeset{} = changeset, _opts, %{tenant: collection}) do
    collection = maybe_collection_from_id(collection)
    path = Changeset.get_argument(changeset, :path)
    filename = Changeset.get_argument(changeset, :filename)

    attachment = %{path: path, filename: filename, collection: collection}

    Changeset.manage_relationship(changeset, :attachment, attachment, type: :create)
  end

  defp maybe_collection_from_id(%Collection{} = collection), do: collection

  defp maybe_collection_from_id(maybe_id) do
    case Collection.get_by_id(maybe_id) do
      {:ok, collection} -> collection
      _ -> nil
    end
  end
end
