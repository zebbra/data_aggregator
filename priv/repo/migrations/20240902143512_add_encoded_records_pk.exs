defmodule DataAggregator.Repo.Migrations.AddEncodedRecordsPk do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:encoded_records) do
      modify :id, :uuid, primary_key: true
    end
  end
end
