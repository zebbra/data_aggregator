defmodule DataAggregatorWeb.Components.EnvInfo do
  @moduledoc """
  This module contains components for displaying system information.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Badge

  @doc """
  Renders a badge with the current env name.

  ## Examples

  ```heex
  <.env_name_badge />
  ```
  """
  def env_name_badge(assigns) do
    {stage, color} =
      case Application.get_env(:data_aggregator, :env_name) do
        stage when stage in [nil, "", "prod"] -> {nil, nil}
        "dev" -> {"Development", "orange"}
        "staging" -> {"Staging", "blue"}
        stage -> {String.capitalize(stage), "red"}
      end

    assigns = assign(assigns, stage: stage, color: color)

    ~H"""
    <.badge :if={@stage} color={@color} class="mx-5 px-4">
      {@stage}
    </.badge>
    """
  end

  @doc """
  returns for which env name which border color scheme is loaded
  """
  def env_name_border do
    case Application.get_env(:data_aggregator, :env_name) do
      stage when stage in [nil, "", "prod"] -> ""
      "dev" -> "border-t-4 border-yellow-500"
      "staging" -> "border-t-4 border-sky-400"
      _ -> "border-t-4 border-red-500"
    end
  end

  @doc """
  Returns the version tag of the application.
  """
  def version_tag do
    {:ok, vsn} = :application.get_key(:data_aggregator, :vsn)

    List.to_string(vsn)
  end
end
