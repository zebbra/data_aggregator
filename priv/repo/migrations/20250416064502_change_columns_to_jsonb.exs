defmodule DataAggregator.Repo.Migrations.ChangeColumnsToJsonb do
  use Ecto.Migration

  def up do
    alter table(:imports) do
      add :columns_tmp, :jsonb
    end

    execute("""
    UPDATE imports
    SET columns_tmp = to_jsonb(columns)
    """)

    alter table(:imports) do
      remove :columns
    end

    rename table(:imports), :columns_tmp, to: :columns
  end

  def down do
    alter table(:imports) do
      add :columns_tmp, {:array, :jsonb}
    end

    execute("""
    UPDATE imports
    SET columns_tmp = ARRAY(
      SELECT jsonb_array_elements(columns)
    )
    """)

    alter table(:imports) do
      remove :columns
    end

    rename table(:imports), :columns_tmp, to: :columns
  end
end
