defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Components do
  @moduledoc """
  This module contains components for the collection > image upload live view.
  """
  use DataAggregatorWeb, :html

  alias DataAggregator.Records.ImageUpload

  @states AshStateMachine.Info.state_machine_all_states(ImageUpload)

  def image_upload_state_badge(%{image_upload: image_upload} = assigns) when is_struct(image_upload) do
    # progress =
    #   case image_upload.state do
    #     :extracting -> image_upload.extract_progress
    #     :mapping -> image_upload.map_progress
    #     _ -> nil
    #   end

    progress = nil

    assigns
    |> assign(:state, image_upload.state)
    |> assign(:progress, progress)
    |> assign(:image_upload, nil)
    |> image_upload_state_badge()
  end

  def image_upload_state_badge(assigns) do
    ~H"""
    <.badge class="pr-3" color={state_color(@state)}>
      <.image_upload_state_icon state={@state} />
      <.image_upload_state_badge_label state={@state} progress={@progress} />
    </.badge>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  # def image_upload_state_badge_label(%{state: :extracting} = assigns) do
  #   ~H"""
  #   <.progress max={1} value={@progress} class="progress-info w-16 leading-4" />
  #   """
  # end

  # def image_upload_state_badge_label(%{state: :extraction_queued} = assigns) do
  #   ~H"""
  #   <.progress max={1} value={} class="progress-info opacity-75 w-16" />
  #   """
  # end

  def image_upload_state_badge_label(assigns) do
    ~H"""
    <span><%= state_translation(@state) %></span>
    """
  end

  def state_color(state) do
    cond do
      state in [:new] -> "gray"
      state in [:extraction_queued, :extracting, :mapping_queued, :mapping] -> "blue"
      state in [:extracted, :mapped] -> "green"
      state in [:extraction_failed, :mapping_failed] -> "red"
    end
  end

  attr :state, :atom, required: true, values: @states

  def image_upload_state_icon(%{state: state} = assigns) do
    {icon, class} = image_upload_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
  end

  defp image_upload_state_icon_class(state) do
    cond do
      state in [:new] ->
        {"hero-clock-solid", "text-base-content opacity-60"}

      state in [:extraction_queued, :extracting, :mapping_queued, :mapping] ->
        {"hero-cog-6-tooth-solid", "text-info animate-spin"}

      state in [:extracted, :mapped] ->
        {"hero-check-circle-solid", "text-success"}

      state in [:extraction_failed, :mapping_failed] ->
        {"hero-x-circle-solid", "text-error"}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp state_translation(state) do
    cond do
      state in [:new] -> ~t"New"m
      state in [:extraction_queued] -> ~t"Extraction queued"m
      state in [:mapping_queued] -> ~t"Mapping queued"m
      state in [:extracting] -> ~t"Extracting"m
      state in [:mapping] -> ~t"Mapping"m
      state in [:extracted] -> ~t"Extracted"m
      state in [:mapped] -> ~t"Mapped"m
      state in [:extraction_failed] -> ~t"Extraction failed"m
      state in [:mapping_failed] -> ~t"Mapping failed"m
    end
  end
end
