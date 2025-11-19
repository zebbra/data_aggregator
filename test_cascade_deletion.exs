#!/usr/bin/env mix run

defmodule TestCascadeDeletion do
  @moduledoc false
  alias Ecto.Adapters.SQL

  def run do
    Logger.configure(level: :info)

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("TESTING CASCADE DELETION BEHAVIOR")
    IO.puts(String.duplicate("=", 80) <> "\n")

    IO.puts("=== STEP 1: Check current foreign key constraints ===\n")
    check_constraints()

    IO.puts("\n=== STEP 2: Create test data ===\n")
    test_data = create_test_data()

    IO.puts("\n=== STEP 3: Verify data BEFORE deletion ===\n")
    verify_data(test_data.collection_id, "BEFORE")

    IO.puts("\n=== STEP 4: Delete collection (triggers partition drop) ===\n")
    delete_collection(test_data.collection_id)

    IO.puts("\n=== STEP 5: Verify data AFTER deletion ===\n")
    verify_data(test_data.collection_id, "AFTER")

    IO.puts("\n=== STEP 6: Final constraint check ===\n")
    check_constraints()

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("TEST COMPLETE")
    IO.puts(String.duplicate("=", 80) <> "\n")
  end

  defp check_constraints do
    query = """
    SELECT
      tc.table_name,
      tc.constraint_name,
      pg_get_constraintdef(c.oid) as constraint_def
    FROM information_schema.table_constraints tc
    JOIN pg_constraint c ON c.conname = tc.constraint_name
    WHERE tc.table_name IN ('validation_request_records', 'validation_request_records_versions')
    AND tc.constraint_type = 'FOREIGN KEY'
    ORDER BY tc.table_name, tc.constraint_name
    """

    {:ok, result} = SQL.query(DataAggregator.Repo, query, [])

    if Enum.empty?(result.rows) do
      IO.puts("  ❌ NO FOREIGN KEY CONSTRAINTS FOUND!")
      IO.puts("  This is the problem - constraints were removed and not recreated!")
    else
      IO.puts("  Foreign key constraints present:")

      for [table, constraint, _def] <- result.rows do
        IO.puts("    ✓ #{table}.#{constraint}")
      end
    end
  end

  defp create_test_data do
    {:ok, result} =
      SQL.query(
        DataAggregator.Repo,
        """
        INSERT INTO collections (
          id, name, code, description, owner, type, state,
          grscicoll_reference, inserted_at, updated_at
        )
        VALUES (
          gen_random_uuid(),
          'Test Cascade Collection',
          'TEST_CASCADE',
          'Test collection to verify cascade deletion',
          'test_owner',
          'physical',
          'draft',
          'test_ref',
          NOW(),
          NOW()
        )
        RETURNING id::text
        """,
        []
      )

    [[collection_id]] = result.rows
    IO.puts("  ✓ Created collection: #{collection_id}")

    {:ok, uuid_bin} = Ecto.UUID.dump(collection_id)

    {:ok, result} =
      SQL.query(
        DataAggregator.Repo,
        """
        INSERT INTO records (collection_id, tax_scientific_name, mte_catalog_number, inserted_at, updated_at)
        VALUES ($1, 'Test species', 'TEST123', NOW(), NOW())
        RETURNING id::text
        """,
        [uuid_bin]
      )

    [[record_id]] = result.rows
    IO.puts("  ✓ Created record: #{record_id}")

    {:ok, uuid_bin_col} = Ecto.UUID.dump(collection_id)
    {:ok, uuid_bin_rec} = Ecto.UUID.dump(record_id)

    {:ok, result} =
      SQL.query(
        DataAggregator.Repo,
        """
        INSERT INTO validation_request_records (collection_id, record_id, data, inserted_at, updated_at)
        VALUES ($1, $2, '{}'::jsonb, NOW(), NOW())
        RETURNING id::text
        """,
        [uuid_bin_col, uuid_bin_rec]
      )

    [[vrr_id]] = result.rows
    IO.puts("  ✓ Created validation_request_record: #{vrr_id}")

    {:ok, uuid_bin_vrr} = Ecto.UUID.dump(vrr_id)

    {:ok, result} =
      SQL.query(
        DataAggregator.Repo,
        """
        INSERT INTO validation_request_records_versions (
          collection_id,
          version_source_id,
          version_action_type,
          changes,
          version_inserted_at,
          version_updated_at
        )
        VALUES ($1, $2, 'create', '{}'::jsonb, NOW(), NOW())
        RETURNING id::text
        """,
        [uuid_bin_col, uuid_bin_vrr]
      )

    [[version_id]] = result.rows
    IO.puts("  ✓ Created validation_request_record_version: #{version_id}")

    %{
      collection_id: collection_id,
      record_id: record_id,
      vrr_id: vrr_id,
      version_id: version_id
    }
  end

  defp verify_data(collection_id, stage) do
    {:ok, uuid_bin} = Ecto.UUID.dump(collection_id)

    queries = [
      {"records", "SELECT COUNT(*) FROM records WHERE collection_id = $1"},
      {"validation_request_records", "SELECT COUNT(*) FROM validation_request_records WHERE collection_id = $1"},
      {"validation_request_records_versions",
       "SELECT COUNT(*) FROM validation_request_records_versions WHERE collection_id = $1"}
    ]

    for {table, query} <- queries do
      {:ok, result} = SQL.query(DataAggregator.Repo, query, [uuid_bin])
      [[count]] = result.rows

      status =
        case {stage, count} do
          {"BEFORE", n} when n > 0 -> "✓"
          {"AFTER", 0} -> "✓"
          {"AFTER", n} when n > 0 -> "❌ ORPHANED DATA"
          _ -> "⚠️"
        end

      IO.puts("  #{status} #{table}: #{count} rows")
    end

    if stage == "AFTER" do
      {:ok, uuid_bin} = Ecto.UUID.dump(collection_id)

      {:ok, result} =
        SQL.query(
          DataAggregator.Repo,
          "SELECT COUNT(*) FROM validation_request_records_versions WHERE collection_id = $1",
          [uuid_bin]
        )

      [[count]] = result.rows

      if count > 0 do
        IO.puts("\n  🚨 PROBLEM DETECTED!")
        IO.puts("  #{count} validation_request_records_versions rows still exist")
        IO.puts("  These are orphaned records that should have been deleted!")
        IO.puts("  They reference a collection that no longer exists.")
      end
    end
  end

  defp delete_collection(collection_id) do
    IO.puts("  Deleting collection #{collection_id}...")
    IO.puts("  (This will trigger the drop_partitions_for_collection trigger)")

    {:ok, uuid_bin} = Ecto.UUID.dump(collection_id)

    {:ok, _} =
      SQL.query(
        DataAggregator.Repo,
        "DELETE FROM collections WHERE id = $1",
        [uuid_bin]
      )

    IO.puts("  ✓ Collection deleted")
  end
end

TestCascadeDeletion.run()
