defmodule DataAggregator.Repo.Migrations.MigrateAttachmentCollectionId do
  use Ecto.Migration

  def up do
    # Update from Exports
    execute("""
      UPDATE file_attachments fa
      SET collection_id = e.collection_id
      FROM exports e
      WHERE fa.id = e.attachment_id
    """)

    # Update from Imports (attachment)
    execute("""
      UPDATE file_attachments fa
      SET collection_id = i.collection_id
      FROM imports i
      WHERE fa.id = i.attachment_id
    """)

    # Update from Imports (error_log)
    execute("""
      UPDATE file_attachments fa
      SET collection_id = i.collection_id
      FROM imports i
      WHERE fa.id = i.error_log_id
    """)

    # Update from Publications
    execute("""
      UPDATE file_attachments fa
      SET collection_id = p.collection_id
      FROM publications p
      WHERE fa.id = p.attachment_id
    """)

    # Update from Validation Requests
    execute("""
      UPDATE file_attachments fa
      SET collection_id = vr.collection_id
      FROM validation_requests vr
      WHERE fa.id = vr.attachment_id
    """)

    # Update from Image Uploads (attachment)
    execute("""
      UPDATE file_attachments fa
      SET collection_id = iu.collection_id
      FROM image_uploads iu
      WHERE fa.id = iu.attachment_id
    """)

    # Update from Image Uploads (upload_log)
    execute("""
      UPDATE file_attachments fa
      SET collection_id = iu.collection_id
      FROM image_uploads iu
      WHERE fa.id = iu.upload_log_id
    """)

    # Update from Record Images
    execute("""
      UPDATE file_attachments fa
      SET collection_id = ri.collection_id
      FROM record_images ri
      WHERE fa.id = ri.attachment_id
    """)

    # Update from Validation Responses (attachment)
    execute("""
      UPDATE file_attachments fa
      SET collection_id = vrc.collection_id
      FROM validation_responses vr
      JOIN validation_response_2_collections vrc ON vr.id = vrc.validation_response_id
      WHERE fa.id = vr.attachment_id
    """)

    # Update from Validation Responses (error_log)
    execute("""
      UPDATE file_attachments fa
      SET collection_id = vrc.collection_id
      FROM validation_responses vr
      JOIN validation_response_2_collections vrc ON vr.id = vrc.validation_response_id
      WHERE fa.id = vr.error_log_id
    """)
  end

  def down do
    # we can't rollback this migration because data might have changed already. rollbacks have to be done manually.
  end
end
