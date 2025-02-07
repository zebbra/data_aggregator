defmodule DataAggregator.Repo.Migrations.RenameUserRoles do
  @doc """
  Rename user roles.
  """

  use Ecto.Migration

  def up do
    execute """
    UPDATE users
    SET roles = ARRAY(
      SELECT CASE
        WHEN role = 'collection_digitizer' THEN 'collection_administrator'
        WHEN role = 'data_administrator' THEN 'data_digitizer'
        ELSE role
      END
      FROM unnest(roles) AS role
    )
    """
  end

  def down do
    execute """
    UPDATE users
    SET roles = ARRAY(
      SELECT CASE
        WHEN role = 'collection_administrator' THEN 'collection_digitizer'
        WHEN role = 'data_digitizer' THEN 'data_administrator'
        ELSE role
      END
      FROM unnest(roles) AS role
    )
    """
  end
end
