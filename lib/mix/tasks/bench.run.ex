defmodule Mix.Tasks.Bench.Run do
  @shortdoc "Run benchmark scenarios and record timings"

  @moduledoc """
  Spawns a fresh `mix bench.run.single` subprocess per (scenario, run). The
  subprocess restores its snapshot and measures one scenario — keeping each
  run in its own BEAM avoids stale Oban / pool state when the DB schema is
  replaced mid-flight.

  Requires `MIX_ENV=bench` and snapshots from `mix bench.seed --size <N>`.

  ## Options

    * `--size` (default: 10_000)
    * `--scenario` — restrict to one of #{inspect(DataAggregator.Bench.Scenarios.known())}
    * `--runs` (default: 1)
  """

  use Mix.Task

  alias DataAggregator.Bench
  alias DataAggregator.Bench.Scenarios

  @switches [size: :integer, scenario: :string, runs: :integer]

  def run(args) do
    if Mix.env() != :bench, do: Mix.raise("bench.run must run with MIX_ENV=bench")

    {opts, _, _} = OptionParser.parse(args, switches: @switches)
    size = opts[:size] || 10_000
    runs = opts[:runs] || 1
    scenarios = pick(opts[:scenario])

    results_file = Bench.new_results_file()
    Mix.shell().info("writing results to #{results_file}")

    for name <- scenarios, run_ix <- 1..runs do
      Mix.shell().info("[#{name}] run #{run_ix}/#{runs}")

      args = [
        "bench.run.single",
        "--size",
        to_string(size),
        "--scenario",
        name,
        "--run",
        to_string(run_ix),
        "--results-file",
        results_file
      ]

      case System.cmd("mix", args, env: [{"MIX_ENV", "bench"}], into: IO.stream(:stdio, :line)) do
        {_, 0} -> :ok
        {_, code} -> Mix.raise("[#{name}] run #{run_ix} exited with code #{code}")
      end
    end

    Mix.shell().info("\ndone — results: #{results_file}")
    Mix.Task.run("bench.report", ["--file", results_file])
  end

  defp pick(nil), do: Scenarios.defaults()

  defp pick(name) do
    if name in Scenarios.known() do
      [name]
    else
      Mix.raise("unknown scenario: #{name} (known: #{Enum.join(Scenarios.known(), ", ")})")
    end
  end
end
