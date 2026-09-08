defmodule DataAggregator.Repo.Migrations.UnsetCollectionIdForValidationResponses do
  use Ecto.Migration

  def up do
    # unset collection_id on all attachments of validation responses, to avoid having them deleted
    # when cleaning up deleted collection medias
    execute("""
      UPDATE file_attachments fa
      SET collection_id = NULL
      FROM validation_responses vr
      JOIN validation_response_2_collections vrc ON vr.id = vrc.validation_response_id
      WHERE fa.id = vr.error_log_id
    """)
  end

  def down do
    execute("""
      UPDATE file_attachments fa
      SET collection_id = vrc.collection_id
      FROM validation_responses vr
      JOIN validation_response_2_collections vrc ON vr.id = vrc.validation_response_id
      WHERE fa.id = vr.error_log_id
    """)
  end
end
