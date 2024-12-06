defmodule DataAggregatorWeb.CollectionLive.Export.Components do
  @moduledoc """
  This module contains components for the collection > export live view.
  """
  use DataAggregatorWeb, :html

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias DataAggregator.Records.Export

  @states AshStateMachine.Info.state_machine_all_states(Export)

  attr :export, Export, required: false
  attr :state, :atom, required: false, values: @states
  attr :progress, :float, required: false, default: nil

  def export_state_badge(%{export: export} = assigns) when is_struct(export) do
    progress = if export.state == :exporting, do: export.export_progress

    assigns
    |> assign(:state, export.state)
    |> assign(:progress, progress)
    |> assign(:export, nil)
    |> export_state_badge()
  end

  def export_state_badge(assigns) do
    ~H"""
    <.badge class="pr-3" color={state_color(@state)}>
      <.export_state_icon state={@state} />
      <.export_state_badge_label state={@state} progress={@progress} />
    </.badge>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def export_state_badge_label(%{state: :exporting} = assigns) do
    ~H"""
    <.progress max={1} value={@progress} class="progress-info w-16 leading-4" />
    """
  end

  def export_state_badge_label(%{state: :queued} = assigns) do
    ~H"""
    <.progress max={1} value={} class="progress-info opacity-75 w-16" />
    """
  end

  def export_state_badge_label(assigns) do
    ~H"""
    <span>{state_translation(@state)}</span>
    """
  end

  def state_color(state) do
    cond do
      state in [:pending] -> "gray"
      state in [:queued, :exporting, :running] -> "blue"
      state in [:exported] -> "green"
      state in [:failed] -> "red"
      true -> "gray"
    end
  end

  attr :state, :atom, required: true, values: @states

  def export_state_icon(%{state: state} = assigns) do
    {icon, class} = export_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp export_state_icon_class(state) do
    cond do
      state in [:pending] ->
        {"hero-clock-solid", "text-base-content opacity-60"}

      state in [:exporting, :queued, :running] ->
        {"hero-cog-6-tooth-solid", "text-info animate-spin"}

      state in [:exported] ->
        {"hero-check-circle-solid", "text-success"}

      state in [:failed] ->
        {"hero-x-circle-solid", "text-error"}

      true ->
        {"hero-clock-solid", "text-base-content opacity-60"}
    end
  end

  defp state_translation(state) do
    cond do
      state in [:pending] -> ~t"Pending"m
      state in [:queued] -> ~t"Queued"m
      state in [:exporting, :running] -> ~t"Exporting"m
      state in [:exported] -> ~t"Exported"m
      state in [:failed] -> ~t"Failed"m
      true -> ~t"Unknown"m
    end
  end
end
