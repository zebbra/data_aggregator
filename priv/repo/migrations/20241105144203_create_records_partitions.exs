defmodule DataAggregator.Repo.Migrations.CreateRecordsPartitions do
  use Ecto.Migration

  @tables [
    approved_records: %{
      fk: "approved_records_record_id_fkey",
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

  @table_names Enum.map(@tables, &elem(&1, 0))

  def up do
    # First drop all foreign key constraints to records (or encoded_records in case of encoded_records_versions)
    for {table, %{fk: fk}} <- @tables |> Enum.filter(&Map.has_key?(elem(&1, 1), :fk)) do
      execute "ALTER TABLE #{table} DROP CONSTRAINT #{fk}"
    end

    for {table, opts} <- @tables do
      pk = Map.get(opts, :pk, "(collection_id, id)")
      # Drop the primary key constraint and add a new one with _orig suffix
      # so that the primary key in the partition table can be named the same.
      # For records and encoded_records (and the versions of them) this also
      # makes sure that we use compsite primary keys (collection_id, id) as
      # this is not supported within the model dsl / snapshots if we use
      # ash_paper_trail
      execute "ALTER TABLE #{table} DROP CONSTRAINT #{table}_pkey"

      execute "ALTER TABLE #{table} ADD CONSTRAINT #{table}_pkey_orig PRIMARY KEY #{pk}"

      # Rename the table to #{table}_orig so we can create a new one with partitions
      execute "ALTER TABLE IF EXISTS #{table} RENAME TO #{table}_orig"

      execute "CREATE TABLE #{table} (LIKE #{table}_orig INCLUDING ALL) PARTITION BY LIST (collection_id)"

      # Create partitions for existing collections
      execute """
        DO $$
        DECLARE
          collection_id uuid;
          partition_sql text;
        BEGIN
          FOR collection_id IN
            SELECT id FROM public.collections
          LOOP
            partition_sql := format(
              'CREATE TABLE #{table}_%s PARTITION OF #{table} FOR VALUES IN (''%s''::uuid);',
              replace(collection_id::text, '-', ''), collection_id
            );
            EXECUTE partition_sql;
          END LOOP;
        END $$;
      """

      # Copy data from #{table}_orig to #{table} partitions
      execute """
        DO $$
        DECLARE
          col_list text;
        BEGIN
          SELECT string_agg(column_name, ', ') INTO col_list FROM information_schema.columns WHERE table_name = '#{table}_orig' AND column_name NOT IN ('tsv','mids_level_one','mids_level_two','mids_level_three','mids_level_four','iucn_redlist');
          EXECUTE 'INSERT INTO #{table} (' || col_list || ') SELECT ' || col_list || ' FROM #{table}_orig;';
        END $$;
      """
    end

    # Re-create the foreign key constraints
    for {table, %{fk: fk, col: col, ref: ref}} <-
          @tables |> Enum.filter(&Map.has_key?(elem(&1, 1), :ref)) do
      execute """
        ALTER TABLE #{table}
        ADD CONSTRAINT #{fk} FOREIGN KEY (collection_id, #{col}) REFERENCES #{ref} (collection_id, id) ON DELETE CASCADE ON UPDATE CASCADE;
      """
    end

    # Function to create partitions before collection insert
    execute """
      CREATE OR REPLACE FUNCTION create_partitions_for_collection()
      RETURNS TRIGGER AS $$
      DECLARE
        table_name text;
      BEGIN
        FOR table_name IN
          SELECT unnest(ARRAY[#{Enum.join(@table_names |> Enum.map(&"'#{&1}'"), ",")}])
        LOOP
          EXECUTE format(
            'CREATE TABLE %s_%s PARTITION OF %s FOR VALUES IN (''%s''::uuid);',
            table_name, replace(NEW.id::text, '-', ''), table_name, NEW.id
          );
        END LOOP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    """

    # Trigger to call the function before insert
    execute """
      CREATE TRIGGER before_collection_insert_partitions
      BEFORE INSERT ON collections
      FOR EACH ROW
      EXECUTE FUNCTION create_partitions_for_collection();
    """

    # Function to drop partitions before collection delete
    execute """
      CREATE OR REPLACE FUNCTION drop_partitions_for_collection()
      RETURNS TRIGGER AS $$
      DECLARE
        table_name text;
      BEGIN
        FOR table_name IN
          SELECT unnest(ARRAY[#{Enum.join(@table_names |> Enum.map(&"'#{&1}'"), ",")}])
        LOOP
          EXECUTE format('DROP TABLE IF EXISTS %s_%s CASCADE;', table_name, replace(OLD.id::text, '-', ''));
        END LOOP;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
    """

    # Trigger to call the function before delete
    execute """
      CREATE TRIGGER before_collection_delete_partitions
      BEFORE DELETE ON collections
      FOR EACH ROW
      EXECUTE FUNCTION drop_partitions_for_collection();
    """
  end

  def down do
    # First drop all foreign key constraints to records (or encoded_records in case of encoded_records_versions)
    for {table, %{fk: fk}} <- @tables |> Enum.filter(&Map.has_key?(elem(&1, 1), :fk)) do
      execute "ALTER TABLE #{table} DROP CONSTRAINT IF EXISTS #{fk}"
    end

    for {table, opts} <- @tables do
      pk =
        if Map.get(opts, :composite_pk) == false do
          # Resources records and encoded_records (and the versions of them) did not have a
          # a composite primary key due to the limitations of ash_paper_trail. Thus we need
          # to use pk "(id)" here
          "(id)"
        else
          # Either restore to defined pk or use the default one (collection_id, id)
          Map.get(opts, :pk, "(collection_id, id)")
        end

      # Drop the partitioned table and rename the original table back
      execute "DROP TABLE #{table} CASCADE"
      execute "ALTER TABLE #{table}_orig RENAME TO #{table}"
      execute "ALTER TABLE #{table} DROP CONSTRAINT #{table}_pkey_orig"
      # Undo primary key renaming
      execute "ALTER TABLE #{table} ADD CONSTRAINT #{table}_pkey PRIMARY KEY #{pk}"
    end

    # Re-create the foreign key constraints
    for {table, %{fk: fk, col: col, ref: ref}} <- @tables do
      execute """
        ALTER TABLE #{table}
        ADD CONSTRAINT #{fk} FOREIGN KEY (collection_id, #{col}) REFERENCES #{ref} (collection_id, id) ON DELETE CASCADE ON UPDATE CASCADE;
      """
    end

    # Remove triggers and functions
    execute "DROP TRIGGER before_collection_insert_partitions ON collections"
    execute "DROP FUNCTION create_partitions_for_collection"
    execute "DROP TRIGGER before_collection_delete_partitions ON collections"
    execute "DROP FUNCTION drop_partitions_for_collection"
  end
end
