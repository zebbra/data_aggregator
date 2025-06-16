# data_aggregator/priv/repo/migrations/20250616101010_fix_partition_constraint_cascading.exs
defmodule DataAggregator.Repo.Migrations.FixPartitionConstraintCascading do
  use Ecto.Migration

  @tables [
    validated_records: %{
      fk: "validated_records_record_id_fkey",
      col: "record_id",
      ref: "records"
    },
    encoded_records: %{
      fk: "encoded_records_record_id_fkey",
      col: "record_id",
      ref: "records",
      composite_pk: false
    },
    encoded_records_versions: %{
      fk: "encoded_records_versions_version_source_id_fkey",
      col: "version_source_id",
      ref: "encoded_records",
      composite_pk: false
    },
    import_records: %{
      fk: "import_records_record_id_fkey",
      pk: "(collection_id, import_id, record_id)",
      col: "record_id",
      ref: "records"
    },
    published_records: %{
      fk: "published_records_record_id_fkey",
      col: "record_id",
      ref: "records"
    },
    record_encoding_results: %{
      fk: "record_encoding_results_record_id_fkey",
      col: "record_id",
      ref: "records"
    },
    record_images: %{
      fk: "record_images_record_id_fkey",
      col: "record_id",
      ref: "records"
    },
    records: %{
      composite_pk: false
    },
    records_versions: %{
      fk: "records_versions_version_source_id_fkey",
      col: "version_source_id",
      ref: "records",
      composite_pk: false
    }
  ]

  # Order tables by dependency - child tables first, then parent tables
  @drop_order [
    :encoded_records_versions,
    :records_versions,
    :validated_records,
    :published_records,
    :import_records,
    :record_encoding_results,
    :record_images,
    :encoded_records,
    :records
  ]

  @table_names Enum.map(@tables, &elem(&1, 0))

  def up do
    # Replace the drop_partitions_for_collection function to handle constraints properly
    execute """
      CREATE OR REPLACE FUNCTION drop_partitions_for_collection()
      RETURNS TRIGGER AS $$
      DECLARE
        tbl_name text;
        partition_name text;
        drop_order text[] := ARRAY[#{Enum.join(@drop_order |> Enum.map(&"'#{&1}'"), ",")}];
        dropped_constraints text[];
        constraint_info record;
      BEGIN
        dropped_constraints := ARRAY[]::text[];

        -- First, temporarily drop ALL foreign key constraints that reference any partition we're about to drop
        -- This is necessary because PostgreSQL doesn't allow dropping partitions that have dependent constraints

        -- Drop constraints that reference records partitions
        FOR constraint_info IN
          SELECT
            tc.constraint_name as cname,
            tc.table_name as tname,
            kcu.column_name as col,
            ccu.table_name as ref_table,
            ccu.column_name as ref_col
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY'
          AND (
            tc.constraint_name LIKE '%_record_id_fkey'
            OR tc.constraint_name LIKE '%_version_source_id_fkey'
          )
        LOOP
          BEGIN
            EXECUTE format('ALTER TABLE %s DROP CONSTRAINT IF EXISTS %s', constraint_info.tname, constraint_info.cname);
            dropped_constraints := array_append(dropped_constraints, constraint_info.tname || '.' || constraint_info.cname);
            RAISE NOTICE 'Temporarily dropped constraint: %.%', constraint_info.tname, constraint_info.cname;
          EXCEPTION
            WHEN others THEN
              RAISE NOTICE 'Could not drop constraint %.%: %', constraint_info.tname, constraint_info.cname, SQLERRM;
          END;
        END LOOP;

        -- Now drop partitions in dependency order
        FOREACH tbl_name IN ARRAY drop_order
        LOOP
          partition_name := format('%s_%s', tbl_name, replace(OLD.id::text, '-', ''));

          -- Check if partition exists before trying to drop it
          IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = partition_name) THEN
            BEGIN
              -- Drop the partition
              EXECUTE format('DROP TABLE %s;', partition_name);
              RAISE NOTICE 'Dropped partition: %', partition_name;
            EXCEPTION
              WHEN others THEN
                RAISE NOTICE 'Could not drop partition %: %', partition_name, SQLERRM;
            END;
          END IF;
        END LOOP;

        -- Recreate all the foreign key constraints we temporarily dropped
        -- We'll recreate them based on our known table structure

        -- Recreate constraints for tables that reference records
        IF 'validated_records.validated_records_record_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE validated_records ADD CONSTRAINT validated_records_record_id_fkey
            FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate validated_records_record_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'encoded_records.encoded_records_record_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE encoded_records ADD CONSTRAINT encoded_records_record_id_fkey
            FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate encoded_records_record_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'import_records.import_records_record_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE import_records ADD CONSTRAINT import_records_record_id_fkey
            FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate import_records_record_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'published_records.published_records_record_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE published_records ADD CONSTRAINT published_records_record_id_fkey
            FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate published_records_record_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'record_encoding_results.record_encoding_results_record_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE record_encoding_results ADD CONSTRAINT record_encoding_results_record_id_fkey
            FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate record_encoding_results_record_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'record_images.record_images_record_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE record_images ADD CONSTRAINT record_images_record_id_fkey
            FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate record_images_record_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'records_versions.records_versions_version_source_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE records_versions ADD CONSTRAINT records_versions_version_source_id_fkey
            FOREIGN KEY (collection_id, version_source_id) REFERENCES records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate records_versions_version_source_id_fkey: %', SQLERRM;
          END;
        END IF;

        IF 'encoded_records_versions.encoded_records_versions_version_source_id_fkey' = ANY(dropped_constraints) THEN
          BEGIN
            ALTER TABLE encoded_records_versions ADD CONSTRAINT encoded_records_versions_version_source_id_fkey
            FOREIGN KEY (collection_id, version_source_id) REFERENCES encoded_records (collection_id, id)
            ON DELETE CASCADE ON UPDATE CASCADE;
          EXCEPTION WHEN others THEN
            RAISE NOTICE 'Could not recreate encoded_records_versions_version_source_id_fkey: %', SQLERRM;
          END;
        END IF;

        RAISE NOTICE 'Completed dropping partitions for collection %', OLD.id;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
    """

    # Clean up any orphaned data and recreate constraints
    for {table, %{fk: fk, col: col, ref: ref}} <-
          @tables |> Enum.filter(&Map.has_key?(elem(&1, 1), :ref)) do
      # First, clean up any orphaned records that would violate the foreign key constraint
      execute """
        DO $$
        DECLARE
          partition_name text;
          collection_uuid uuid;
          deleted_count integer;
          total_deleted integer := 0;
        BEGIN
          RAISE NOTICE 'Cleaning up orphaned data in #{table}...';

          -- Get all collection IDs to check each partition
          FOR collection_uuid IN SELECT id FROM collections LOOP
            partition_name := '#{table}_' || replace(collection_uuid::text, '-', '');

            -- Check if partition exists
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = partition_name) THEN
              -- Delete orphaned records from this partition
              EXECUTE format('
                WITH deleted AS (
                  DELETE FROM %s
                  WHERE (collection_id, #{col}) NOT IN (
                    SELECT collection_id, id FROM #{ref}
                    WHERE collection_id = ''%s''::uuid
                  )
                  RETURNING 1
                )
                SELECT COUNT(*) FROM deleted', partition_name, collection_uuid) INTO deleted_count;

              total_deleted := total_deleted + deleted_count;

              IF deleted_count > 0 THEN
                RAISE NOTICE 'Deleted % orphaned records from partition %', deleted_count, partition_name;
              END IF;
            END IF;
          END LOOP;

          IF total_deleted > 0 THEN
            RAISE NOTICE 'Total orphaned records deleted from #{table}: %', total_deleted;
          END IF;
        END $$;
      """

      # Now recreate the foreign key constraint if it doesn't exist
      execute """
        DO $$
        BEGIN
          RAISE NOTICE 'Checking/creating foreign key constraint #{fk}...';

          -- Drop the constraint if it exists (in case it's malformed)
          IF EXISTS (
            SELECT 1 FROM information_schema.table_constraints
            WHERE constraint_name = '#{fk}'
            AND table_name = '#{table}'
          ) THEN
            RAISE NOTICE 'Dropping existing constraint #{fk} to recreate it';
            ALTER TABLE #{table} DROP CONSTRAINT #{fk};
          END IF;

          -- Create the foreign key constraint
          ALTER TABLE #{table}
          ADD CONSTRAINT #{fk} FOREIGN KEY (collection_id, #{col})
          REFERENCES #{ref} (collection_id, id)
          ON DELETE CASCADE ON UPDATE CASCADE;

          RAISE NOTICE 'Successfully created foreign key constraint #{fk}';

        EXCEPTION
          WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Could not create foreign key constraint #{fk} due to remaining data inconsistencies. Please check the data manually.';
          WHEN others THEN
            RAISE EXCEPTION 'Error creating constraint #{fk}: %', SQLERRM;
        END $$;
      """
    end

    # Handle published_records special case - it has multiple foreign keys
    execute """
      DO $$
      BEGIN
        RAISE NOTICE 'Checking/creating additional foreign key constraints for published_records...';

        -- Drop existing constraints if they exist
        IF EXISTS (
          SELECT 1 FROM information_schema.table_constraints
          WHERE constraint_name = 'published_records_publication_id_fkey'
          AND table_name = 'published_records'
        ) THEN
          ALTER TABLE published_records DROP CONSTRAINT published_records_publication_id_fkey;
        END IF;

        -- Create the publication foreign key constraint
        ALTER TABLE published_records
        ADD CONSTRAINT published_records_publication_id_fkey
        FOREIGN KEY (publication_id) REFERENCES publications (id)
        ON DELETE SET NULL ON UPDATE CASCADE;

        RAISE NOTICE 'Successfully created published_records_publication_id_fkey constraint';

      EXCEPTION
        WHEN others THEN
          RAISE NOTICE 'Error creating published_records publication constraint: %', SQLERRM;
      END $$;
    """

    # Also create any missing primary key constraints that might have been dropped
    execute """
      DO $$
      DECLARE
        tbl_name text;
      BEGIN
        -- Check and recreate primary key constraints for tables that need them
        FOR tbl_name IN
          SELECT unnest(ARRAY[#{Enum.join(@table_names |> Enum.map(&"'#{&1}'"), ",")}])
        LOOP
          -- Check if primary key constraint exists
          IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints
            WHERE constraint_type = 'PRIMARY KEY'
            AND table_name = tbl_name
          ) THEN
            CASE tbl_name
              WHEN 'records', 'encoded_records', 'encoded_records_versions', 'records_versions' THEN
                -- These tables should have (collection_id, id) as primary key
                EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (collection_id, id)', tbl_name, tbl_name || '_pkey');
                RAISE NOTICE 'Created primary key constraint for %', tbl_name;
              WHEN 'import_records' THEN
                -- This table has a composite primary key
                EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (collection_id, import_id, record_id)', tbl_name, tbl_name || '_pkey');
                RAISE NOTICE 'Created primary key constraint for %', tbl_name;
              WHEN 'published_records' THEN
                -- Published records has (collection_id, id) as primary key but also has record_id as part of composite
                EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (collection_id, id)', tbl_name, tbl_name || '_pkey');
                RAISE NOTICE 'Created primary key constraint for %', tbl_name;
              ELSE
                -- Other tables should have (collection_id, id) as primary key
                IF EXISTS (
                  SELECT 1 FROM information_schema.columns
                  WHERE table_name = tbl_name AND column_name = 'id'
                ) THEN
                  EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (collection_id, id)', tbl_name, tbl_name || '_pkey');
                  RAISE NOTICE 'Created primary key constraint for %', tbl_name;
                END IF;
            END CASE;
          END IF;
        END LOOP;
      END $$;
    """
  end

  def down do
    # Revert back to the original function with CASCADE
    execute """
      CREATE OR REPLACE FUNCTION drop_partitions_for_collection()
      RETURNS TRIGGER AS $$
      DECLARE
        tbl_name text;
      BEGIN
        FOR tbl_name IN
          SELECT unnest(ARRAY[#{Enum.join(@table_names |> Enum.map(&"'#{&1}'"), ",")}])
        LOOP
          EXECUTE format('DROP TABLE IF EXISTS %s_%s CASCADE;', tbl_name, replace(OLD.id::text, '-', ''));
        END LOOP;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
    """
  end
end
