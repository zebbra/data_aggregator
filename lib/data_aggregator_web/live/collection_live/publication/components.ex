defmodule DataAggregatorWeb.CollectionLive.Publication.Components do
  @moduledoc """
  This module contains components for the collection > publication live view.
  """
  use DataAggregatorWeb, :html

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias DataAggregator.Records.Publication

  @states AshStateMachine.Info.state_machine_all_states(Publication)

  attr :publication, Publication, required: false
  attr :state, :atom, required: false, values: @states
  attr :progress, :float, required: false, default: nil

  def publication_state_badge(%{publication: publication} = assigns) when is_struct(publication) do
    progress = if publication.state == :publishing, do: publication.publication_progress

    assigns
    |> assign(:state, publication.state)
    |> assign(:progress, progress)
    |> assign(:publication, nil)
    |> publication_state_badge()
  end

  def publication_state_badge(assigns) do
    ~H"""
    <.badge class="pr-3" color={state_color(@state)}>
      <.publication_state_icon state={@state} />
      <.publication_state_badge_label state={@state} progress={@progress} />
    </.badge>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def publication_state_badge_label(%{state: :publishing} = assigns) do
    ~H"""
    <.progress max={1} value={@progress} class="progress-info w-16 leading-4" />
    """
  end

  def publication_state_badge_label(%{state: :queued} = assigns) do
    ~H"""
    <.progress max={1} value={} class="progress-info w-16 opacity-75" />
    """
  end

  def publication_state_badge_label(assigns) do
    ~H"""
    <span>{state_translation(@state)}</span>
    """
  end

  def state_color(state) do
    cond do
      state in [:pending] -> "gray"
      state in [:queued, :publishing, :running] -> "blue"
      state in [:done] -> "green"
      state in [:failed] -> "red"
      true -> "gray"
    end
  end

  attr :state, :atom, required: true, values: @states

  def publication_state_icon(%{state: state} = assigns) do
    {icon, class} = publication_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp publication_state_icon_class(state) do
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
      state in [:publishing, :running] -> ~t"Processing"m
      state in [:done] -> ~t"Done"m
      state in [:failed] -> ~t"Failed"m
      true -> ~t"Unknown"m
    end
  end

  attr :channel, :atom, required: true, values: [:fast_track, :validation]

  def publication_channel_badge(%{channel: :fast_track} = assigns) do
    ~H"""
    <.badge class="tooltip" color="gray" data-tip={~t"Publication to the Gbif Switzerland Portal"m}>
      <.icon name="hero-globe-alt" class="size-4 shrink-0" />
      <span class="text-nowrap pr-1.5">{~t"Publication"m}</span>
    </.badge>
    """
  end
end
