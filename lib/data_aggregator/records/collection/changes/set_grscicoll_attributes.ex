defmodule DataAggregator.Records.Collection.Changes.SetGrsciCollAttributes do
  @moduledoc """
  This change sets attributes of a GrSciColl collection by looking up the collection at gbif.org
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Gbif

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    reference = Changeset.get_argument_or_attribute(changeset, :grscicoll_reference)

    case Gbif.RestAPI.get_grscicoll_collection_attributes(reference, [
           "code",
           "name",
           "numberSpecimens",
           "institutionKey",
           "institutionCode",
           "institutionName"
         ]) do
      {:ok, attributes} ->
        changes =
          %{
            code: attributes["code"],
            name: attributes["name"],
            items_to_digitize: attributes["numberSpecimens"] || 0,
            grscicoll_institution_key: attributes["institutionKey"],
            grscicoll_institution_code: attributes["institutionCode"],
            grscicoll_institution_name: attributes["institutionName"]
          }

        Changeset.change_attributes(changeset, changes)

      {:error, error} ->
        Logger.warning(error)

        Changeset.add_error(changeset, field: :code, message: inspect(error))
    end
  end
end
