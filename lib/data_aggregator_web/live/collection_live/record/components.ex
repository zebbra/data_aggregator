defmodule DataAggregatorWeb.CollectionLive.Record.Components do
  @moduledoc """
  This module contains components for the collection > record live view.
  """
  use DataAggregatorWeb, :html

  attr :state, :atom,
    required: true,
    values: [
      :not_published,
      :publishing,
      :in_publication,
      :published,
      :stale,
      :publication_failed
    ]

  def publication_status_badge(assigns) do
    case assigns.state do
      :publishing ->
        ~H"""
        <.badge class="px-2 tooltip tooltip-info" color="blue" data-tip={~t"Publication in progress"m}>
          <.icon name="hero-cog-6-tooth-solid" class="size-5 shrink-0 animate-spin" />
          <span class="text-nowrap px-1.5"><%= ~t"Publishing"m %></span>
        </.badge>
        """

      :in_publication ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-info"
          color="blue"
          data-tip={~t"Record is in the publication pipeline - no further action required"m}
        >
          <.icon name="hero-information-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"In Publication"m %></span>
        </.badge>
        """

      :published ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-success"
          color="green"
          data-tip={~t"Record was successful published"m}
        >
          <.icon name="hero-check-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Published"m %></span>
        </.badge>
        """

      :stale ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-warning"
          color="orange"
          data-tip={~t"Record was changed after publishing it and has to be republished"m}
        >
          <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Stale"m %></span>
        </.badge>
        """

      :publication_failed ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-error"
          color="red"
          data-tip={~t"Publication failed. Process should be started again"m}
        >
          <.icon name="hero-x-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Failed"m %></span>
        </.badge>
        """

      _ ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-ghost"
          color="gray"
          data-tip={~t"No publication information available. Publish the collection to see the status"m}
        >
          <.icon name="hero-question-mark-circle-solid" class="size-5 shrink-0" />
          <span class="text-nowrap px-1.5"><%= ~t"Not Published"m %></span>
        </.badge>
        """
    end
  end

  @level [0, 1, 2, 3, 4]

  attr :level, :integer, required: true, values: @level

  def mids_level_indicator(assigns) do
    color_dot_range = Range.new(1, assigns.level)
    gray_dot_range = Range.new(1, 4 - assigns.level)

    assigns = assign(assigns, :color_dot_range, color_dot_range)
    assigns = assign(assigns, :gray_dot_range, gray_dot_range)

    ~H"""
    <div
      class={["tooltip tooltip-top flex h-8 justify-evenly rounded-full p-2", level_indicator(@level)]}
      data-tip={level_translation(@level)}
    >
      <div :for={_level <- @color_dot_range} :if={@level > 0}>
        <div class="h-4 w-4 rounded-full bg-current" />
      </div>
      <div :for={_level <- @gray_dot_range} :if={@level < 4}>
        <div class="bg-base-100 h-4 w-4 rounded-full " />
      </div>
    </div>
    """
  end

  defp level_indicator(level) do
    gray = "bg-base-300 text-base-content/60 tooltip-ghost border border-black-white/20"
    blue = "bg-info/10 text-info tooltip-info border border-info/30"
    green = "bg-success/10 text-success tooltip-success border border-success/30"
    red = "bg-error/10 text-error tooltip-error border border-error/30"
    orange = "bg-warning/10 text-warning tooltip-warning border border-warning/30"

    case level do
      4 -> green
      3 -> blue
      2 -> orange
      1 -> red
      0 -> gray
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp level_translation(level) do
    case level do
      0 ->
        ~t"Please submit at least the institution code with your data, to reach the lowest quality level"m

      1 ->
        ~t"Add all of the following fields to reach level two: taxon_id, part_of_organism"m

      2 ->
        ~t"Add the following fields to reach level three: event_date, ecorded_by, type_status, original_name_usage, continent, country, county, decimal_latitude, decimal_longitude, higher_geography, locality, state_province, verbatim_depth, verbatim_elevation, year_collection_entrance, occurrence_id"m

      3 ->
        ~t"Add one of the follwing fields to reach level four: verbatim_event_date, identified_by, identification_qualifier, identification_verification_status, last_verified_by, verbatim_identification, georeferenced_by, georeference_verification_status, verbatim_coordinates, verbatim_latitude, verbatim_longitude, verbatim_locality, associated_media, completeness, other_catalog_numbers, verbatim_label"m

      4 ->
        ~t"Record has a top quality. Add more data fields to improve your collections relevance"m
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Record.Components
    end
  end
end
