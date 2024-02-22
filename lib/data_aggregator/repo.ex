er_diagram = Path.expand("../../docs/erd.mmd", __DIR__)

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
  #{File.read!(er_diagram)}
  ```
  """

  use AshPostgres.Repo, otp_app: :data_aggregator

  # ensure module is recompiled when the ERD changes
  @external_resource er_diagram

  # Installs Postgres extensions that ash commonly uses
  def installed_extensions do
    ["ash-functions", "uuid-ossp", "citext", AshUUID.PostgresExtension]
  end
end
