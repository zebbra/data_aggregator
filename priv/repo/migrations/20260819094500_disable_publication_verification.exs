defmodule DataAggregator.Repo.Migrations.DisablePublicationVerification do
  @moduledoc """
  Retires the API based publication verification.

  Verifying a publication asked the GBIF occurrence API once per record, which hit GBIF's
  rate limit. That produced wrong publication states and a stream of API errors in the logs.
  Publication is now asserted rather than verified: records move `:publishing` -> `:published`
  after a grace period, driven by
  `DataAggregator.Records.Publication.Scheduler.PublicationFinalizer`.

  See `docs/adr/0001-publication-is-asserted-not-verified.md`.

  This migration

  1. resets every record still sitting in the retired `:in_publication` state to
     `:not_published`, and
  2. deletes the `PublicationVerifier` Oban jobs, whose worker module no longer exists.

  The reset is deliberately raw SQL and therefore writes no paper trail versions: no user
  performed this transition, and fabricating one per record would both spam the activity feed
  and claim a state change that never happened. The activity feed keeps showing the historical
  `In Publication` entry while the current status reads `Not Published` - that disagreement is
  accurate history, which is also why `:in_publication` stays in the enum.
  """

  use Ecto.Migration

  @verifier_worker "DataAggregator.Records.Publication.Scheduler.PublicationVerifier"
  @verifier_queue "publication_verifications"

  def up do
    execute """
    DO $$
    DECLARE
        affected_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO affected_count
        FROM records
        WHERE publication_status = 'in_publication';

        RAISE NOTICE 'Resetting % record(s) from ''in_publication'' to ''not_published''', affected_count;
    END $$;
    """

    execute """
    UPDATE records
    SET publication_status = 'not_published',
        updated_at = NOW()
    WHERE publication_status = 'in_publication';
    """

    execute """
    DO $$
    DECLARE
        affected_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO affected_count
        FROM oban_jobs
        WHERE worker = '#{@verifier_worker}'
           OR queue = '#{@verifier_queue}';

        RAISE NOTICE 'Deleting % PublicationVerifier Oban job(s)', affected_count;
    END $$;
    """

    execute """
    DELETE FROM oban_jobs
    WHERE worker = '#{@verifier_worker}'
       OR queue = '#{@verifier_queue}';
    """
  end

  def down do
    # We do not roll back data changes. The `PublicationVerifier` worker and the
    # `publication_verifications` queue no longer exist, so recreating its jobs would only
    # produce jobs that can never run, and we cannot tell which records were reset from
    # `in_publication` versus which were already `not_published`.
    execute """
    DO $$
    BEGIN
        RAISE NOTICE 'Publication verification was retired. Nothing to roll back.';
    END $$;
    """
  end
end
