defmodule DataAggregatorWeb.CollectionLive.Import.Components do
  @moduledoc """
  This module contains components for the collection > import live view.
  """
  use DataAggregatorWeb, :html

  alias DataAggregator.Records.Import

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  @states AshStateMachine.Info.state_machine_all_states(Import)

  attr :import, Import, required: false
  attr :state, :atom, required: false, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge(%{import: import} = assigns) when is_struct(import) do
    progress =
      case import.state do
        :importing -> import.import_progress
        :validating -> import.validation_progress
        _ -> nil
      end

    assigns
    |> assign(:state, import.state)
    |> assign(:progress, progress)
    |> assign(:import, nil)
    |> import_state_badge()
  end

  def import_state_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex h-8 items-center space-x-1.5 rounded-full py-1 pr-3 pl-1.5 text-sm font-medium ring-1 ring-inset",
      import_state_badge_class(@state)
    ]}>
      <.import_state_icon state={@state} />
      <.import_state_badge_label state={@state} progress={@progress} />
    </span>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge_label(%{state: :importing} = assigns) do
    ~H"""
    <.progress max={1} value={@progress} class="progress-info w-16 leading-4" />
    """
  end

  def import_state_badge_label(%{state: :import_queued} = assigns) do
    ~H"""
    <.progress max={1} value={} class="progress-info opacity-75 w-16" />
    """
  end

  def import_state_badge_label(assigns) do
    ~H"""
    <span><%= @state |> Atom.to_string() |> String.capitalize() %></span>
    """
  end

  def import_state_badge_class(state) do
    gray = "bg-base-300 text-base-content/60 ring-base-content/30"
    blue = "bg-info/10 text-info ring-info/20"
    green = "bg-success/10 text-success ring-success/20"
    red = "bg-error/10 text-error ring-error/20"

    cond do
      state in [:pending] -> gray
      state in [:import_queued, :importing] -> blue
      state in [:imported] -> green
      state in [:failed] -> red
    end
  end

  attr :state, :atom, required: true, values: @states

  def import_state_icon(%{state: state} = assigns) do
    {icon, class} = import_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp import_state_icon_class(state) do
    cond do
      state in [:pending] ->
        {"hero-clock-solid", "text-base-content opacity-60"}

      state in [:importing, :import_queued] ->
        {"hero-cog-6-tooth-solid", "text-info animate-spin"}

      state in [:imported] ->
        {"hero-check-circle-solid", "text-success"}

      state in [:failed] ->
        {"hero-x-circle-solid", "text-error"}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Import.Components
    end
  end
end
