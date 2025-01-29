defmodule DataAggregator.Repo.Migrations.RemoveAddInstitutionCodeEntriesFromEncodingResults do
  @moduledoc """
  This migration removes the entries form 'record_encoding_results' table
  that have 'add_institution_code' in the 'catalog' column
  """

  use Ecto.Migration

  def up do
    execute("DELETE FROM record_encoding_results WHERE catalog = 'add_institution_code'")

    execute(
      "DELETE FROM encoded_records_versions WHERE version_action_name = 'update' AND changes ? 'oth_institution_id' AND changes ? 'oth_institution_code'"
    )
  end

  def down do
  end
end
