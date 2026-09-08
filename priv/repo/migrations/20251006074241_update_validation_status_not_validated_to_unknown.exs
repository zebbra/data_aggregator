defmodule DataAggregator.Repo.Migrations.UpdateValidationStatusNotValidatedToUnknown do
  @moduledoc """
  Updates validation_status from legacy values to 'unknown' for any records that may have
  outdated default values. This cleans up legacy data where validation_status was set to
  values that are no longer valid in the enum.

  This migration updates the following legacy statuses to 'unknown':
  - 'not_validated' (outdated default)
  - 'in_validation' (renamed to 'validating')
  - 'validating' (will be updated if found, though this is a valid status)

  This is mostly used for the production environment where older records may still have
  these values.

  The ValidationStatusType enum only supports: :unknown, :validating, :requested,
  :validated, :not_validated
  """
  use Ecto.Migration

  def up do
    # First, let's check and log how many records will be affected
    execute """
    DO $$
    DECLARE
      not_validated_count INTEGER;
      in_validation_count INTEGER;
      validating_count INTEGER;
      total_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO not_validated_count
      FROM records
      WHERE validation_status = 'not_validated';

      SELECT COUNT(*) INTO in_validation_count
      FROM records
      WHERE validation_status = 'in_validation';

      SELECT COUNT(*) INTO validating_count
      FROM records
      WHERE validation_status = 'validating';

      total_count := not_validated_count + in_validation_count + validating_count;

      RAISE NOTICE 'Found % total records that will be updated to ''unknown'':', total_count;
      RAISE NOTICE '  - % records with validation_status = ''not_validated''', not_validated_count;
      RAISE NOTICE '  - % records with validation_status = ''in_validation''', in_validation_count;
      RAISE NOTICE '  - % records with validation_status = ''validating''', validating_count;
    END $$;
    """

    # Update any records where validation_status is one of the legacy values to 'unknown'
    execute """
    UPDATE records
    SET validation_status = 'unknown',
        updated_at = NOW()
    WHERE validation_status IN ('not_validated', 'in_validation', 'validating');
    """

    # Log completion
    execute """
    DO $$
    DECLARE
      remaining_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO remaining_count
      FROM records
      WHERE validation_status IN ('not_validated', 'in_validation', 'validating');

      IF remaining_count > 0 THEN
        RAISE WARNING 'Still found % records with legacy validation_status values after migration', remaining_count;
      ELSE
        RAISE NOTICE 'Migration completed successfully. No records with legacy validation_status values remain.';
      END IF;
    END $$;
    """
  end

  def down do
    # We do not rollback data changes
  end
end
