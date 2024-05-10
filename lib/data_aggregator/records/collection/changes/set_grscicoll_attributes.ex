defmodule DataAggregator.Records.Collection.Changes.SetGrsciCollAttributes do
  @moduledoc """
  This change sets attributes of a GrSciColl collection by looking up the collection at gbif.org
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Gbif.GrSciColl

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    reference = Changeset.get_argument_or_attribute(changeset, :grscicoll_reference)

    case GrSciColl.get_grscicoll_attributes(reference, ["code", "name", "institutionKey"]) do
      {:ok, attributes} ->
        Changeset.change_attribute(
          changeset,
          :grscicoll_institution_key,
          attributes["institutionKey"]
        )

        Changeset.change_attribute(changeset, :code, attributes["code"])
        Changeset.change_attribute(changeset, :name, attributes["name"])

      {:error, error} ->
        Changeset.add_error(changeset, field: :code, message: inspect(error))
    end
  end
end
