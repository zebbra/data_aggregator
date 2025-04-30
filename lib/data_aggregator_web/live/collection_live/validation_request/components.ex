defmodule DataAggregatorWeb.CollectionLive.ValidationRequest.Components do
  @moduledoc """
  This module contains components for the collection > validation_request live view.
  """
  use DataAggregatorWeb, :html

  alias DataAggregator.Records.ValidationRequest

  @states AshStateMachine.Info.state_machine_all_states(ValidationRequest)

  attr :validation_request, ValidationRequest, required: false
  attr :state, :atom, required: false, values: @states
  attr :progress, :float, required: false, default: nil

  def validation_request_state_badge(%{validation_request: validation_request} = assigns)
      when is_struct(validation_request) do
    progress =
      if validation_request.state == :validating,
        do: validation_request.validation_request_progress

    assigns
    |> assign(:state, validation_request.state)
    |> assign(:progress, progress)
    |> assign(:validation_request, nil)
    |> validation_request_state_badge()
  end

  def validation_request_state_badge(assigns) do
    ~H"""
    <.badge class="pr-3" color={state_color(@state)}>
      <.validation_request_state_icon state={@state} />
      <.validation_request_state_badge_label state={@state} progress={@progress} />
    </.badge>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def validation_request_state_badge_label(%{state: :queued} = assigns) do
    ~H"""
    <.progress max={1} value={} class="progress-info w-16 opacity-75" />
    """
  end

  def validation_request_state_badge_label(assigns) do
    ~H"""
    <span>{state_translation(@state)}</span>
    """
  end

  def state_color(state) do
    cond do
      state in [:pending] -> "gray"
      state in [:queued, :running] -> "blue"
      state in [:done] -> "green"
      state in [:failed] -> "red"
      true -> "gray"
    end
  end

  attr :state, :atom, required: true, values: @states

  def validation_request_state_icon(%{state: state} = assigns) do
    {icon, class} = validation_request_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp validation_request_state_icon_class(state) do
    cond do
      state in [:pending] ->
        {"hero-clock-solid", "text-base-content opacity-60"}

      state in [:publishing, :queued, :running] ->
        {"hero-cog-6-tooth-solid", "text-info animate-spin"}

      state in [:done] ->
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
      state in [:running] -> ~t"Processing"m
      state in [:done] -> ~t"Done"m
      state in [:failed] -> ~t"Failed"m
      true -> ~t"Unknown"m
    end
  end
end
