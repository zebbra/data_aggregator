defmodule DataAggregator.Repo.Migrations.MigratePublishedRecordsRecordIdsToUuids do
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication.PublishedRecord

  use Ecto.Migration

  def up do
    migrate_published_records_ids_to(:uuid)
  end

  def down do
    migrate_published_records_ids_to(:id)
  end

  defp migrate_published_records_ids_to(id_or_uuid) do
    # Get all collections
    collections = Collection |> Ash.read!()

    # Process each collection
    Enum.each(collections, fn collection ->
      # Get all published records for this collection
      PublishedRecord
      |> Ash.Query.set_tenant(collection)
      |> Ash.stream!()
      # Update each record directly using Ecto
      |> Enum.each(fn published_record ->
        new_record_id = convert_to(id_or_uuid, published_record.record_id)

        published_record_id =
          convert_to(:uuid, published_record.id) |> Ecto.UUID.dump!()

        collection_id =
          convert_to(:uuid, published_record.collection_id) |> Ecto.UUID.dump!()

        query = """
          UPDATE published_records SET record_id = $2 WHERE id = $1 AND collection_id = $3
        """

        Ecto.Adapters.SQL.query!(DataAggregator.Repo, query, [
          published_record_id,
          new_record_id,
          collection_id
        ])
      end)
    end)
  end

  defp convert_to(:uuid, id) do
    with [_prefix, string_id] <- String.split(id, "_"),
         {:ok, string_uuid} <- AshUUID.Encoder.decode(string_id) do
      string_uuid
    end
  end

  defp convert_to(:id, uuid) do
    "rec_" <> AshUUID.Encoder.encode(uuid)
  end
end
