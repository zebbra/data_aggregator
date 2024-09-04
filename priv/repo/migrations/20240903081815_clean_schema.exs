defmodule DataAggregator.Repo.Migrations.CleanSchema do
  use Ecto.Migration

  @moduledoc """
  Cleans the schema from all tables and columns that are not needed anymore. This has been created by re-generating a migration
  using the current Ash resources and then comparing the resulting database schemas.
  """

  def up do
    drop_if_exists table(:attribute_resolving_strategies)
    drop_if_exists table(:dwc_attributes)
    drop_if_exists table(:import_files)
    drop_if_exists table(:change_events)
    drop_if_exists table(:attachments)
    drop_if_exists table(:catalogs)

    alter table(:imports) do
      remove_if_exists :amount_of_rows
    end
  end

  def down do
    # no-op
  end
end
