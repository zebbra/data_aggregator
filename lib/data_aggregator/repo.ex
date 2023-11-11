defmodule DataAggregator.Repo do
  @moduledoc """
  Repository for resources using `AshPostgres` as data layer.

  ## Database Extensions

  To install database extensions, add them to the `installed_extensions/0` function
  then run

  ```shell
  mix ash.postgres.generate_migration
  ```

  to generate a migration.

  ### ERD

  ```mermaid
  #{"docs/erd.mmd" |> File.read!()}
  ```
  """

  use AshPostgres.Repo, otp_app: :data_aggregator

  # Installs Postgres extensions that ash commonly uses
  def installed_extensions do
    ["ash-functions", "uuid-ossp", "citext", AshUUID.PostgresExtension]
  end
end
