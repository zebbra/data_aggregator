defmodule DataAggregatorWeb.Components.SystemInfo do
  @moduledoc """
  This module contains components for displaying system information.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Badge

  @doc """
  Renders a badge with the current system stage and info.

  ## Examples

  ```heex
  <.system_stage_badge />
  ```
  """

  def system_stage_badge(assigns) do
    :data_aggregator
    |> Application.get_env(:system_stage)
    |> case do
      :dev ->
        ~H"""
        <.badge color="orange" class="mx-5 px-4">
          Development
        </.badge>
        """

      :zebbra ->
        ~H"""
        <.badge color="red" class="mx-5 px-4">
          Zebbra
        </.badge>
        """

      :staging ->
        ~H"""
        <.badge color="blue" class="mx-5 px-4">
          Staging
        </.badge>
        """

      :prod ->
        ~H"""
        """
    end
  end

  def system_stage_border do
    :data_aggregator
    |> Application.get_env(:system_stage)
    |> case do
      :dev -> "border-t-4 border-yellow-500"
      :zebbra -> "border-t-4 border-red-500"
      :staging -> "border-t-4 border-sky-400"
      :prod -> ""
    end
  end

  def version_tag do
    Application.get_env(:data_aggregator, :app_version)
  end
end
