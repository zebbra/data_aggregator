defmodule DataAggregatorWeb.ValidationResponseLive.Components do
  @moduledoc """
  This module contains components for the validation response live view.
  """

  use DataAggregatorWeb, :html

  alias DataAggregator.Records.ValidationResponse

  @states AshStateMachine.Info.state_machine_all_states(ValidationResponse)

  attr :type, :atom, required: true

  def validation_response_type_badge(assigns) do
    ~H"""
    <.badge class="px-3" color={type_color(@type)}>
      {type_translation(@type)}
    </.badge>
    """
  end

  attr :validation_response, ValidationResponse, required: false
  attr :state, :atom, required: false, values: @states
  attr :progress, :float, required: false, default: nil

  def validation_response_state_badge(%{validation_response: validation_response} = assigns)
      when is_struct(validation_response) do
    assigns
    |> assign(:state, validation_response.state)
    |> assign(:validation_response, nil)
    |> validation_response_state_badge()
  end

  def validation_response_state_badge(assigns) do
    ~H"""
    <.badge class="pr-3" color={state_color(@state)}>
      <.validation_response_state_icon state={@state} />
      <.validation_response_state_badge_label state={@state} progress={@progress} />
    </.badge>
    """
  end

  attr :state, :atom, required: true, values: @states

  def validation_response_state_badge_label(assigns) do
    ~H"""
    <span>{state_translation(@state)}</span>
    """
  end

  attr :state, :atom, required: true, values: @states

  def validation_response_state_icon(%{state: state} = assigns) do
    {icon, class} = validation_response_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp validation_response_state_icon_class(state) do
    cond do
      state in [:pending] ->
        {"hero-clock-solid", "text-base-content opacity-60"}

      state in [:queued, :running] ->
        {"hero-cog-6-tooth-solid", "text-info animate-spin"}

      state in [:done] ->
        {"hero-check-circle-solid", "text-success"}

      state in [:failed] ->
        {"hero-x-circle-solid", "text-error"}
    end
  end

  defp type_translation(:validated), do: ~t"Validated"
  defp type_translation(:not_validated), do: ~t"Not Validated"

  defp state_translation(state) do
    cond do
      state in [:pending] -> ~t"Pending"m
      state in [:queued] -> ~t"Queued"m
      state in [:running] -> ~t"Running"m
      state in [:done] -> ~t"Done"m
      state in [:failed] -> ~t"Failed"m
    end
  end

  defp type_color(:validated), do: "blue"
  defp type_color(:not_validated), do: "red"

  defp state_color(state) do
    cond do
      state in [:pending] -> "gray"
      state in [:queued, :running] -> "blue"
      state in [:done] -> "green"
      state in [:failed] -> "red"
    end
  end
end
