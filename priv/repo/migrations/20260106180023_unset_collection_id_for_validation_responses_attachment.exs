defmodule DataAggregator.Repo.Migrations.UnsetCollectionIdForValidationResponses do
  use Ecto.Migration

  def up do
    # unset collection_id and deleted_at on all attachments of validation responses, to avoid having them deleted
    # when cleaning up deleted collection medias
    execute("""
    UPDATE file_attachments fa
    SET collection_id = NULL, deleted_at = NULL
    FROM validation_responses vr
    JOIN validation_response_2_collections vrc ON vr.id = vrc.validation_response_id
    WHERE fa.id = vr.attachment_id
    """)

    # same for error logs (they are attachments too)
    execute("""
    UPDATE file_attachments fa
    SET collection_id = NULL, deleted_at = NULL
    FROM validation_responses vr
    JOIN validation_response_2_collections vrc ON vr.id = vrc.validation_response_id
    WHERE fa.id = vr.error_log_id
    """)
  end

  def down do
    # data might have changed, no rollback is possible. do it manually.
  end
end
