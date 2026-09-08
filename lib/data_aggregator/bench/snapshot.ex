defmodule DataAggregator.Bench.Snapshot do
  @moduledoc """
  Dump and restore the bench database to/from a named snapshot file.

  A snapshot is a single `.sql` file produced by `pg_dump --clean --if-exists`
  containing both schema and data. `restore/1` drops the existing schema and
  replays the snapshot, which is much faster than re-seeding from scratch.

  Snapshots live in `bench/snapshots/<name>.sql` relative to the repo root.
  """

  require Logger

  @snapshots_dir "bench/snapshots"

  def dump(name) do
    path = path_for(name)
    File.mkdir_p!(Path.dirname(path))
    {:ok, conn} = connection_info()

    args = [
      "--no-owner",
      "--no-privileges",
      "--file=#{path}",
      "--dbname=#{conn.database}",
      "--host=#{conn.hostname}",
      "--port=#{to_string(conn.port)}",
      "--username=#{conn.username}"
    ]

    env = [{"PGPASSWORD", conn.password}]
    Logger.info("pg_dump -> #{path}")

    case System.cmd("pg_dump", args, env: env, stderr_to_stdout: true) do
      {_out, 0} -> {:ok, path}
      {out, code} -> {:error, "pg_dump exited #{code}: #{out}"}
    end
  end

  def restore(name) do
    path = path_for(name)

    if !File.exists?(path) do
      raise "snapshot not found: #{path}"
    end

    {:ok, conn} = connection_info()

    Logger.info("resetting public schema on #{conn.database}")

    case psql_command(conn, "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;") do
      {:ok, _} -> :ok
      {:error, out} -> raise "schema reset failed: #{out}"
    end

    Logger.info("psql restore <- #{path}")

    args = [
      "--quiet",
      "--no-psqlrc",
      "--single-transaction",
      "--set=ON_ERROR_STOP=1",
      "--file=#{path}",
      "--dbname=#{conn.database}",
      "--host=#{conn.hostname}",
      "--port=#{to_string(conn.port)}",
      "--username=#{conn.username}"
    ]

    env = [{"PGPASSWORD", conn.password}]

    case System.cmd("psql", args, env: env, stderr_to_stdout: true) do
      {_out, 0} -> :ok
      {out, code} -> {:error, "psql exited #{code}: #{out}"}
    end
  end

  defp psql_command(conn, sql) do
    args = [
      "--quiet",
      "--no-psqlrc",
      "--set=ON_ERROR_STOP=1",
      "--command=#{sql}",
      "--dbname=#{conn.database}",
      "--host=#{conn.hostname}",
      "--port=#{to_string(conn.port)}",
      "--username=#{conn.username}"
    ]

    env = [{"PGPASSWORD", conn.password}]

    case System.cmd("psql", args, env: env, stderr_to_stdout: true) do
      {out, 0} -> {:ok, out}
      {out, code} -> {:error, "psql exited #{code}: #{out}"}
    end
  end

  def exists?(name), do: File.exists?(path_for(name))

  def path_for(name), do: Path.join([File.cwd!(), @snapshots_dir, "#{name}.sql"])

  defp connection_info do
    config = DataAggregator.Repo.config()

    case Keyword.get(config, :url) do
      nil ->
        {:ok,
         %{
           database: Keyword.fetch!(config, :database),
           hostname: Keyword.fetch!(config, :hostname),
           port: Keyword.get(config, :port, 5432),
           username: Keyword.fetch!(config, :username),
           password: Keyword.fetch!(config, :password)
         }}

      url ->
        parse_url(url)
    end
  end

  defp parse_url(url) do
    uri = URI.parse(url)
    [username, password] = String.split(uri.userinfo || "", ":", parts: 2)

    {:ok,
     %{
       database: String.trim_leading(uri.path || "", "/"),
       hostname: uri.host,
       port: uri.port || 5432,
       username: username,
       password: password
     }}
  end
end
