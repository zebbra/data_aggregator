defmodule Mix.Tasks.Bench.Seed do
  @shortdoc "Seed the bench DB and dump snapshots"

  @moduledoc """
  Produces two snapshots that drive `mix bench.run`:

    * `empty.sql` — schema + catalogs + bench user + bench collection, no
      records. Size-independent; reused by the `import` scenario for every
      `--size`. Built once (takes ~3-5s because of the Swiss-species
      registry import); subsequent runs restore it instead of rebuilding.
    * `ready-<N>.sql` — `empty` + `N` bulk-created records, their encoded
      counterparts, and `SwissSpeciesRegistry` entries for every distinct
      scientific name. Consumed by encode / publish / validate / export /
      validation_response.

  Also regenerates `bench/datasets/dataset-<N>.csv` so the `import` scenario
  has a matching CSV to feed through the real import pipeline.

  Requires `MIX_ENV=bench`.

  ## Options

    * `--size` — number of records to seed (default: 10_000)
    * `--reset` — force rebuild of `empty.sql` (rerun catalog import). Pass
      this after schema/catalog changes, otherwise subsequent seeds reuse
      the existing `empty.sql` for speed.
  """

  use Mix.Task

  alias DataAggregator.Bench
  alias DataAggregator.Bench.Seeder
  alias DataAggregator.Bench.Snapshot

  @switches [size: :integer, reset: :boolean]

  def run(args) do
    if Mix.env() != :bench, do: Mix.raise("bench.seed must run with MIX_ENV=bench")

    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    size = opts[:size] || 10_000

    prepare_empty!(opts[:reset] || false)
    Bench.install_stubs()

    csv = Seeder.ensure_dataset!(size)
    Mix.shell().info("dataset: #{csv}")

    user = Bench.user!()
    collection = Bench.collection!()

    Mix.shell().info("bulk-seeding #{size} records ...")
    {elapsed_us, :ok} = :timer.tc(fn -> Seeder.bulk_seed!(collection, user, size) end)
    Mix.shell().info("bulk-seed: #{div(elapsed_us, 1000)}ms")

    {:ok, ready_path} = Snapshot.dump("ready-#{size}")
    Mix.shell().info("snapshot: #{ready_path}")
  end

  # Ensure the DB is in the "post-catalog, no-records" baseline.
  # Prefer restoring `empty.sql` (fast) over rerunning the full catalog import.
  defp prepare_empty!(reset?) do
    if reset? or not Snapshot.exists?("empty") do
      Mix.shell().info("building empty snapshot (full catalog import)")
      Mix.Task.run("repo.bench.reset")
      Mix.Task.run("app.start")
      Bench.install_stubs()
      _ = Bench.user!()
      _ = Bench.collection!()
      {:ok, empty_path} = Snapshot.dump("empty")
      Mix.shell().info("snapshot: #{empty_path}")
    else
      Mix.shell().info("restoring empty snapshot")
      Mix.Task.run("repo.create", ["--quiet"])
      :ok = Snapshot.restore("empty")
      Mix.Task.run("app.start")
    end
  end
end
