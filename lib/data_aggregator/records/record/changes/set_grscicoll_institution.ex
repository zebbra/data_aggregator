defmodule DataAggregator.Records.Record.Changes.SetGrSciCollInstitution do
  @moduledoc """
  Sets the institution key and code of a GrSciColl collection to the record
  """

  use Ash.Resource.Change

  alias Ash.Changeset

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    set_grscicoll_institution_attributes(changeset)
  end

  defp set_grscicoll_institution_attributes(changeset) do
    with {:ok, changeset} <-
           set_institution_identifier(changeset, :oth_institution_id, :grscicoll_institution_key),
         {:ok, changeset} <-
           set_institution_identifier(
             changeset,
             :oth_institution_code,
             :grscicoll_institution_code
           ) do
      changeset
    else
      error ->
        Logger.error("Error setting institution attributes: #{inspect(error)}")

        changeset
    end
  end

  defp set_institution_identifier(changeset, attribute_on_record, attribute_on_collection) do
    identifier_value = Changeset.get_argument_or_attribute(changeset, attribute_on_record)

    if identifier_value == nil do
      Logger.debug("Setting #{attribute_on_record} ...")

      identifier_value = identifier_from_collection(changeset, attribute_on_collection)

      {:ok, Changeset.change_attribute(changeset, attribute_on_record, identifier_value)}
    else
      Logger.debug("#{attribute_on_record} already set, skipping ...")

      {:ok, changeset}
    end
  end

  defp identifier_from_collection(changeset, attribute) do
    with {:ok, collection} <- extract_collection(changeset),
         {:ok, value} <- extract_attribute_value(collection, attribute) do
      value
    else
      {:error, _} ->
        nil
    end
  end

  defp extract_collection(changeset) do
    case Changeset.get_argument(changeset, :collection) do
      nil ->
        {:error, nil}

      collection ->
        {:ok, collection}
    end
  end

  defp extract_attribute_value(collection, attribute) do
    case Map.get(collection, attribute) do
      nil ->
        Logger.warning("No #{attribute} found in collection")

        {:error, nil}

      value ->
        {:ok, value}
    end
  end
end
