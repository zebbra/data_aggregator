defmodule DataAggregator.Repo.Migrations.UpdateValidationStatusStaleToUnknown do
  @moduledoc """
  Updates validation_status from 'stale' to 'unknown' for any records that may have
  this invalid enum value. This cleans up legacy data where validation_status was
  incorrectly set to 'stale' (which is a valid value for publication_status but not
  for validation_status).

  The ValidationStatusType enum only supports: :unknown, :validating, :requested,
  :validated, :not_validated
  """

  use Ecto.Migration

  def up do
    # First, let's check and log how many records will be affected
    execute """
    DO $$
    DECLARE
        affected_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO affected_count
        FROM records
        WHERE validation_status = 'stale';

        RAISE NOTICE 'Found % records with validation_status = ''stale'' that will be updated to ''unknown''', affected_count;
    END $$;
    """

    # Update any records where validation_status is 'stale' to 'unknown'
    execute """
    UPDATE records
    SET validation_status = 'unknown',
        updated_at = NOW()
    WHERE validation_status = 'stale';
    """

    # Log completion
    execute """
    DO $$
    DECLARE
        remaining_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO remaining_count
        FROM records
        WHERE validation_status = 'stale';

        IF remaining_count > 0 THEN
            RAISE WARNING 'Still found % records with validation_status = ''stale'' after migration', remaining_count;
        ELSE
            RAISE NOTICE 'Migration completed successfully. No records with validation_status = ''stale'' remain.';
        END IF;
    END $$;
    """
  end

  def down do
    # We do not rollback data changes. If you need to rollback, do it manually with SQL UPDATE.

    execute """
    DO $$
    BEGIN
        RAISE NOTICE 'Rolling back validation_status changes. Note: ''stale'' is not a valid enum value for validation_status. We do not rollback.';
    END $$;
    """
  end
end
