defmodule Mix.Tasks.DataAggregator.Records.Convert do
  @shortdoc "Converts records from a file to various formats."

  @moduledoc false
  use Mix.Task

  alias DataAggregator.Records.DataFrame

  def run([src, dst]) do
    Mix.shell().info("Converting #{src} to #{dst} ...")

    with {:ok, df} <- DataFrame.from_file(src),
         :ok <- DataFrame.to_file(df, dst) do
    else
      {:error, error} -> Mix.shell().error("Error: #{inspect(error)}")
    end
  end
end
