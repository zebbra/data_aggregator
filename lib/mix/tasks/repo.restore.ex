defmodule Mix.Tasks.Repo.Restore do
  @shortdoc "Restores the database from a dump file"

  @moduledoc false
  use Mix.Task

  @source "priv/repo/dump/staging.dump"
  @database "data-aggregator-dev"
  # @database "postgresql://postgres:postgres@localhost:5432/data-aggregator-dev"

  @extensions [
    "uuid-ossp",
    "citext",
    "pg_trgm",
    "btree_gin"
  ]

  def run(_args) do
    if Mix.shell().yes?("Drop database and restore from #{@source}?") do
      Mix.Task.run("repo.drop", ["--force-drop"])
      Mix.Task.run("repo.create")

      Enum.each(@extensions, &create_extension/1)

      pg_restore(["--no-acl", "--no-owner", "-d", @database, @source])
    end
  end

  def create_extension(extension) do
    sql = "CREATE EXTENSION IF NOT EXISTS \"#{extension}\""

    Mix.shell().info("Creating extension: #{extension}")

    args = ["-U", "postgres", @database, "-c", sql]
    System.cmd("psql", args)
  end

  def pg_restore(args) do
    System.cmd("pg_restore", ["--verbose"] ++ args)
  end
end
