defmodule Mix.Tasks.Repo.Erd do
  @moduledoc false

  @task "ecto.gen.erd"
  @exts ~w(dbml mmd)

  @shortdoc "Generates ERDs docs/erd.(#{@exts |> Enum.join(",")}) with `#{@task}` (if `ecto_erd` is installed)"

  use Mix.Task

  def run(_args) do
    case Mix.Task.get(@task) do
      nil -> Mix.shell().info("Please install ecto_erd to generate ERDs")
      _task -> for ext <- @exts, do: ecto_gen_erd(ext)
    end
  end

  defp ecto_gen_erd(ext) do
    output = "docs/erd.#{ext}"
    Mix.shell().info("Generating ERD to #{output} ...")
    Mix.Task.rerun(@task, ["--output-path=#{output}"])
  end
end
