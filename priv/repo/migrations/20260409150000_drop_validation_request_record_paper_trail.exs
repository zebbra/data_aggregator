defmodule DataAggregator.Repo.Migrations.DropValidationRequestRecordPaperTrail do
  @moduledoc """
  Drops the `validation_request_records_versions` table.

  AshPaperTrail was removed from `DataAggregator.Records.ValidationRequestRecord`
  because the version history was never read by any production code path. The
  resource itself already acts as a per-record snapshot of the last data sent
  for validation, making the paper trail duplicative and a write-amplification
  source during validation runs.

  This migration was written manually because `mix ash.codegen` does not detect
  orphaned snapshots once the backing resource has been removed from the domain.
  The `down/0` is fully reversible — it recreates the table with the same
  schema, indexes, and deferrable foreign keys as the original creation
  migration (`20250716084806_create_validation_request_resources.exs`).
  """

  use Ecto.Migration

  def up do
    drop_if_exists index(:validation_request_records_versions, [:collection_id, :user_id])

    drop_if_exists index(:validation_request_records_versions, [
                     :collection_id,
                     :version_source_id
                   ])

    drop_if_exists constraint(
                     :validation_request_records_versions,
                     "validation_request_records_versions_user_id_fkey"
                   )

    drop_if_exists constraint(
                     :validation_request_records_versions,
                     "validation_request_records_versions_version_source_id_fkey"
                   )

    drop table(:validation_request_records_versions)
  end

  def down do
    create table(:validation_request_records_versions, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :version_action_type, :text, null: false
      add :collection_id, :uuid, null: false
      add :version_source_id, :uuid, null: false
      add :changes, :map

      add :version_inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :version_updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")

      add :user_id, :uuid
    end

    alter table(:validation_request_records_versions) do
      modify :version_source_id,
             references(:validation_request_records,
               column: :id,
               with: [collection_id: :collection_id],
               name: "validation_request_records_versions_version_source_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :delete_all,
               on_update: :update_all
             )
    end

    execute(
      "ALTER TABLE validation_request_records_versions ALTER CONSTRAINT validation_request_records_versions_version_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    alter table(:validation_request_records_versions) do
      modify :user_id,
             references(:users,
               column: :id,
               name: "validation_request_records_versions_user_id_fkey",
               type: :uuid,
               prefix: "public",
               on_delete: :nilify_all,
               on_update: :update_all
             )
    end

    execute(
      "ALTER TABLE validation_request_records_versions ALTER CONSTRAINT validation_request_records_versions_user_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    create index(:validation_request_records_versions, [:collection_id, :version_source_id])

    create index(:validation_request_records_versions, [:collection_id, :user_id])
  end
end
