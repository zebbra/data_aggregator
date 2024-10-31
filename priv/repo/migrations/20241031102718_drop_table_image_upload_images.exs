defmodule DataAggregator.Repo.Migrations.DropTableImageUploadImages do
  use Ecto.Migration

  def change do
    drop table(:image_upload_images)
  end
end
