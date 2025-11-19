defmodule DataAggregator.Repo.Migrations.SimplifyPartitionDropWithCascade do
  use Ecto.Migration

  @drop_order [
    :encoded_records_versions,
    :records_versions,
    :approved_records,
    :published_records,
    :import_records,
    :record_encoding_results,
    :record_images,
    :encoded_records,
    :records
  ]

  def up do
    # First, clean up orphaned data and restore missing foreign key constraints
    execute("""
    DO $body$
    DECLARE
      deleted_count integer;
    BEGIN
      -- Clean up orphaned validation_request_records that reference deleted records
      DELETE FROM validation_request_records
      WHERE NOT EXISTS (
        SELECT 1 FROM records
        WHERE records.collection_id = validation_request_records.collection_id
        AND records.id = validation_request_records.record_id
      );
      GET DIAGNOSTICS deleted_count = ROW_COUNT;
      IF deleted_count > 0 THEN
        RAISE NOTICE 'Cleaned up % orphaned validation_request_records rows', deleted_count;
      END IF;

      -- Clean up orphaned validation_request_records_versions that reference deleted validation_request_records
      DELETE FROM validation_request_records_versions
      WHERE NOT EXISTS (
        SELECT 1 FROM validation_request_records
        WHERE validation_request_records.collection_id = validation_request_records_versions.collection_id
        AND validation_request_records.id = validation_request_records_versions.version_source_id
      );
      GET DIAGNOSTICS deleted_count = ROW_COUNT;
      IF deleted_count > 0 THEN
        RAISE NOTICE 'Cleaned up % orphaned validation_request_records_versions rows', deleted_count;
      END IF;

      -- Restore validation_request_records -> records constraint if missing
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'validation_request_records_record_id_fkey'
        AND table_name = 'validation_request_records'
      ) THEN
        RAISE NOTICE 'Recreating missing validation_request_records_record_id_fkey constraint';
        ALTER TABLE validation_request_records
        ADD CONSTRAINT validation_request_records_record_id_fkey
        FOREIGN KEY (collection_id, record_id) REFERENCES records (collection_id, id)
        ON DELETE CASCADE ON UPDATE CASCADE;
      END IF;

      -- Restore validation_request_records_versions -> validation_request_records constraint if missing
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'validation_request_records_versions_version_source_id_fkey'
        AND table_name = 'validation_request_records_versions'
      ) THEN
        RAISE NOTICE 'Recreating missing validation_request_records_versions_version_source_id_fkey constraint';
        ALTER TABLE validation_request_records_versions
        ADD CONSTRAINT validation_request_records_versions_version_source_id_fkey
        FOREIGN KEY (collection_id, version_source_id) REFERENCES validation_request_records (collection_id, id)
        ON DELETE CASCADE ON UPDATE CASCADE;
      END IF;
    END $body$;
    """)

    # Now update the trigger to use CASCADE
    execute("""
    CREATE OR REPLACE FUNCTION drop_partitions_for_collection()
    RETURNS TRIGGER AS $$
    DECLARE
      table_name text;
    BEGIN
      FOR table_name IN
        SELECT unnest(ARRAY[#{Enum.join(@drop_order |> Enum.map(&"'#{&1}'"), ",")}])
      LOOP
        EXECUTE format('DROP TABLE IF EXISTS %s_%s CASCADE;', table_name, replace(OLD.id::text, '-', ''));
      END LOOP;
      RETURN OLD;
    END;
    $$ LANGUAGE plpgsql;
    """)
  end

  def down do
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
  end
end
