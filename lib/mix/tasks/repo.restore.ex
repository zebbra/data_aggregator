defmodule Mix.Tasks.Repo.Restore do
  @shortdoc "Restores the database from a dump file"

  @moduledoc false
  use Mix.Task

  @source "priv/repo/dump/staging.dump"
  @database "data_aggregator_dev"

  def run(_args) do
    if Mix.shell().yes?("Drop database and restore from #{@source}?") do
      Mix.Task.run("repo.drop", ["--force-drop"])
      Mix.Task.run("repo.create")

      pg_restore(["--no-acl", "--no-owner", "-d", @database, @source])
    end
  end

  def pg_restore(args) do
    System.cmd("pg_restore", ["--verbose"] ++ args)
  end
end
