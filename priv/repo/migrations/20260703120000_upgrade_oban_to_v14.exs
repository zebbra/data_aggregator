defmodule DataAggregator.Repo.Migrations.UpgradeObanToV14 do
  use Ecto.Migration

  # Adds the `:suspended` value to the `oban_job_state` enum (Oban V14).
  # Idempotent: a no-op in environments already at V14 (e.g. dev), and
  # bumps any environment still below it. Explicit + versioned on purpose,
  # since the unversioned `add_oban.exs` migration won't re-run to advance
  # a stale enum after an Oban dependency upgrade.
  def up, do: Oban.Migration.up(version: 14)

  def down, do: Oban.Migration.down(version: 14)
end
