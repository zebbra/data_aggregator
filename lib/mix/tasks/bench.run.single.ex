defmodule Mix.Tasks.Bench.Run.Single do
  @shortdoc "Internal: run a single bench scenario and record the result"

  @moduledoc """
  Invoked by `mix bench.run` in a fresh subprocess: restore snapshot, install
  stubs, measure, append result. Running each scenario in its own BEAM avoids
  stale Oban / Ecto pool state after a schema restore.

  ## Options

    * `--size` (required)
    * `--scenario` (required)
    * `--run` (default: 1)
    * `--results-file` — JSONL path to append to
  """

  use Mix.Task

  alias DataAggregator.Bench
  alias DataAggregator.Bench.Scenarios
  alias DataAggregator.Bench.Snapshot

  @switches [size: :integer, scenario: :string, run: :integer, results_file: :string]

  def run(args) do
    if Mix.env() != :bench, do: Mix.raise("bench.run.single must run with MIX_ENV=bench")

    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    size = opts[:size] || Mix.raise("--size is required")
    name = opts[:scenario] || Mix.raise("--scenario is required")
    run_ix = opts[:run] || 1
    results_file = opts[:results_file] || Bench.new_results_file()

    snapshot = Scenarios.snapshot_for(name, size)

    if !Snapshot.exists?(snapshot) do
      Mix.raise("missing snapshot #{snapshot}.sql — run `mix bench.seed --size #{size}` first")
    end

    :ok = Snapshot.restore(snapshot)

    Mix.Task.run("app.start")

    Bench.install_stubs()

    user = Bench.user!()
    collection = Bench.collection!()

    Mix.shell().info("[#{name}] measuring ...")
    measurement = Scenarios.run(name, collection, user, size)

    entry = Bench.record(results_file, name, size, measurement, %{run: run_ix})
    Mix.shell().info("[#{name}] run #{run_ix} — #{entry.wall_ms}ms -> #{results_file}")
  end
end
