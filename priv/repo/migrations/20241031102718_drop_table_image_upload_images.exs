defmodule DataAggregator.Repo.Migrations.DropTableImageUploadImages do
  use Ecto.Migration

  def up do
    drop_if_exists table(:image_upload_images)
  end

  def down do
  end
end
