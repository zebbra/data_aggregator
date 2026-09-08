defmodule Mix.Tasks.Bench.Report do
  @shortdoc "Summarise latest bench results and optionally diff against another run"

  @moduledoc """
  Prints median / p95 wall_ms per (size, scenario) from the latest JSONL file
  under `bench/results/`.

  ## Options

    * `--file` — explicit results file to report on (default: most recent)
    * `--compare` — another results file (or SHA prefix) to diff against

  ## Examples

      mix bench.report
      mix bench.report --file bench/results/20260421T100000Z-69b18d18.jsonl
      mix bench.report --compare 40f0b020
  """

  use Mix.Task

  @results_dir "bench/results"
  @switches [file: :string, compare: :string]

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)

    current = resolve_file(opts[:file]) || Mix.raise("no results found in #{@results_dir}")
    current_rows = load(current)

    Mix.shell().info("current: #{current}")
    print_table(current_rows)

    case opts[:compare] do
      nil ->
        :ok

      ref ->
        baseline = resolve_file(ref) || Mix.raise("no baseline found matching #{ref}")
        baseline_rows = load(baseline)
        Mix.shell().info("\nbaseline: #{baseline}")
        print_table(baseline_rows)
        Mix.shell().info("\ndiff (current - baseline):")
        print_diff(current_rows, baseline_rows)
    end
  end

  defp resolve_file(nil), do: latest_file()

  defp resolve_file(hint) do
    if File.exists?(hint) do
      hint
    else
      @results_dir
      |> File.ls!()
      |> Enum.filter(&String.contains?(&1, hint))
      |> Enum.map(&Path.join(@results_dir, &1))
      |> Enum.sort(:desc)
      |> List.first()
    end
  end

  defp latest_file do
    case File.ls(@results_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".jsonl"))
        |> Enum.map(&Path.join(@results_dir, &1))
        |> Enum.sort(:desc)
        |> List.first()

      _ ->
        nil
    end
  end

  defp load(file) do
    file
    |> File.stream!()
    |> Enum.map(&Jason.decode!/1)
  end

  defp print_table(rows) do
    rows
    |> Enum.group_by(fn r -> {r["size"], r["scenario"]} end)
    |> Enum.sort()
    |> Enum.each(fn {{size, scenario}, runs} ->
      wall = Enum.map(runs, & &1["wall_ms"])

      Mix.shell().info(
        "  size=#{size} scenario=#{scenario}  runs=#{length(runs)}  median=#{median(wall)}ms  p95=#{p95(wall)}ms  min=#{Enum.min(wall)}ms  max=#{Enum.max(wall)}ms"
      )
    end)
  end

  defp print_diff(current, baseline) do
    curr = summarise(current)
    base = summarise(baseline)

    curr
    |> Map.keys()
    |> Enum.sort()
    |> Enum.each(&print_diff_row(&1, curr[&1], base[&1]))
  end

  defp print_diff_row({size, scenario}, current, nil) do
    Mix.shell().info("  size=#{size} scenario=#{scenario}  #{current}ms (no baseline)")
  end

  defp print_diff_row({size, scenario}, current, baseline) do
    delta = current - baseline
    arrow = if delta < 0, do: "↓", else: "↑"
    pct = Float.round(delta / baseline * 100, 1)

    Mix.shell().info("  size=#{size} scenario=#{scenario}  #{baseline}ms → #{current}ms  #{arrow} #{pct}%")
  end

  defp summarise(rows) do
    rows
    |> Enum.group_by(fn r -> {r["size"], r["scenario"]} end)
    |> Map.new(fn {k, runs} -> {k, median(Enum.map(runs, & &1["wall_ms"]))} end)
  end

  defp median(values) do
    sorted = Enum.sort(values)
    n = length(sorted)

    cond do
      n == 0 -> 0
      rem(n, 2) == 1 -> Enum.at(sorted, div(n, 2))
      true -> div(Enum.at(sorted, div(n, 2) - 1) + Enum.at(sorted, div(n, 2)), 2)
    end
  end

  defp p95(values) do
    sorted = Enum.sort(values)
    n = length(sorted)

    if n == 0 do
      0
    else
      Enum.at(sorted, min(n - 1, trunc(0.95 * n)))
    end
  end
end
