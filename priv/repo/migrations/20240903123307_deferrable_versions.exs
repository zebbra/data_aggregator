defmodule DataAggregator.Repo.Migrations.DeferrableVersions do
  @moduledoc """
  Make the version references deferrable. When deleting a record, ash_paper_trail will try to create a
  new version for this record which would then violate the foreign key constraint.

  Marking the foreign key constraint as deferrable allows the checks to be deferred until the end of the transaction
  when both the record and versions are deleted.
  """

  use Ecto.Migration

  def up do
    execute(
      "ALTER TABLE encoded_records_versions alter CONSTRAINT encoded_records_versions_version_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )

    execute(
      "ALTER TABLE records_versions alter CONSTRAINT records_versions_version_source_id_fkey DEFERRABLE INITIALLY DEFERRED"
    )
  end

  def down do
    execute(
      "ALTER TABLE records_versions alter CONSTRAINT records_versions_version_source_id_fkey NOT DEFERRABLE"
    )

    execute(
      "ALTER TABLE encoded_records_versions alter CONSTRAINT encoded_records_versions_version_source_id_fkey NOT DEFERRABLE"
    )
  end
end
