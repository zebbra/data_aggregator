defmodule Mix.Tasks.Repo.Dump.Staging do
  @shortdoc "Dumps the database from a Kubernetes pod"

  @moduledoc false
  use Mix.Task

  @namespace "scnat"
  @database "aggregator"
  @labels ~w(-l app=scnat-postgres -l spilo-role=replica)

  @temp "/tmp/database.dump"
  @destination "priv/repo/dump/staging.dump"

  def run(_args) do
    pod = get_pod()

    if Mix.shell().yes?("Dumping database from #{pod} to #{@destination}?") do
      dump_db(pod)
      copy_dump(pod)
    end
  end

  defp dump_db(pod) do
    Mix.shell().info("Dumping database from #{pod} to #{@temp} ...")

    pg_dump = "pg_dump --verbose -Fc -n public -U postgres #{@database} > #{@temp}"

    kubectl(["exec", "-i", pod, "-c", "postgres", "--", "bash", "-c", pg_dump])
  end

  defp copy_dump(pod) do
    Mix.shell().info("Copying dump from #{pod} to #{@destination} ...")

    kubectl(["cp", "#{pod}:#{@temp}", @destination, "--retries", "5"])
  end

  defp get_pod do
    ["get", "pods", "-o", "jsonpath={.items[*].metadata.name}" | @labels]
    |> kubectl()
    |> String.trim()
  end

  defp kubectl(args) do
    case System.cmd("kubectl", ["-n", @namespace] ++ args) do
      {output, 0} -> output
      {output, code} -> raise "kubectl failed with code #{code} and output #{output}"
    end
  end
end
