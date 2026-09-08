defmodule DataAggregator.Repo.Migrations.MigrateRecordEncodingResultsCatalog do
  @moduledoc """
  Migrates old catalog values in record_encoding_results table.
  Changes 'gbif_iucn_redlist' to 'iucn_redlist' and 'gbif_taxonomy' to 'col_taxonomy'.
  """

  use Ecto.Migration

  def up do
    execute "UPDATE record_encoding_results SET catalog = 'iucn_redlist' WHERE catalog = 'gbif_iucn_redlist'"

    execute "UPDATE record_encoding_results SET catalog = 'col_taxonomy' WHERE catalog = 'gbif_taxonomy'"
  end

  def down do
    execute "UPDATE record_encoding_results SET catalog = 'gbif_iucn_redlist' WHERE catalog = 'iucn_redlist'"

    execute "UPDATE record_encoding_results SET catalog = 'gbif_taxonomy' WHERE catalog = 'col_taxonomy'"
  end
end
