defmodule DataAggregator.Repo.Migrations.CleanupUnwantedVersions do
  use Ecto.Migration

  def up do
    execute """
      DELETE FROM records_versions
      WHERE version_action_name IN (
        'check_if_fast_track_pubished',
        'enqueue_encoder',
        'set_encoded',
        'set_encoding',
        'set_encoding_failed'
      );
    """

    execute """
      DELETE FROM encoded_records_versions
      WHERE version_action_name = 'create';
    """
  end

  def down, do: :ok
end
