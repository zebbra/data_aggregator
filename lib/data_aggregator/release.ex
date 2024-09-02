defmodule DataAggregator.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """

  @app :data_aggregator

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def catalog_init do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &eval_catalogs_file(&1))
    end
  end

  defp eval_catalogs_file(_repo) do
    Code.eval_file("repo/catalogs/init.exs", "#{DataAggregator.priv_dir()}")
  end

  def users_init do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &eval_users_file(&1))
    end
  end

  defp eval_users_file(_repo) do
    Code.eval_file("repo/users/init.exs", "#{DataAggregator.priv_dir()}")
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
    Application.ensure_all_started(:req)
    Application.ensure_all_started(:ssl)
  end
end
