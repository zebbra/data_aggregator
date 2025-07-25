defmodule DataAggregator.Repo.Migrations.RenamePublicationChannelValuesApprovalToValidation do
  use Ecto.Migration

  def up do
    execute """
    UPDATE publications
    SET channel = 'validation'
    WHERE channel = 'approval'
    """
  end

  def down do
    execute """
    UPDATE publications
    SET channel = 'approval'
    WHERE channel = 'validation'
    """
  end
end
