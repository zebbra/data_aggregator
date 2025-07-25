defmodule DataAggregator do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  @app :data_aggregator

  def app_dir, do: Application.app_dir(@app)
  def priv_dir, do: :code.priv_dir(@app)
end
