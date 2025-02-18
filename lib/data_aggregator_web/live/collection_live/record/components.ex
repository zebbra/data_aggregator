defmodule DataAggregatorWeb.CollectionLive.Record.Components do
  @moduledoc """
  This module contains components for the collection > record live view.
  """
  use DataAggregatorWeb, :html

  alias DataAggregatorWeb.CollectionLive.Record.ActivityFeed

  attr :href, :string, required: true
  attr :title, :string, required: true
  attr :value, :float, required: true
  attr :desc, :string, required: true
  attr :active, :boolean, default: false

  def scope_stat(assigns) do
    ~H"""
    <.link
      patch={@href}
      class={[
        "btn btn-outline group animate-none lg:stat lg:h-auto lg:text-left",
        @active && "btn-primary lg:border-primary",
        @active == false && "border-base-content/20 lg:border-base-content/20"
      ]}
    >
      <div class={[
        "truncate leading-4 lg:stat-title",
        @active && "lg:text-primary/75 lg:group-hover:text-primary-content",
        @active == false && "lg:group-hover:text-base-100/80"
      ]}>
        {@title}
      </div>
      <div class={["stat-value max-lg:hidden"]}>{format_percent(@value)}</div>
      <div class={[
        "stat-desc max-lg:hidden",
        @active && "lg:text-primary/75 lg:group-hover:text-primary-content",
        @active == false && "lg:group-hover:text-base-100/80"
      ]}>
        {@desc}
      </div>
    </.link>
    """
  end

  attr :title, :string, required: true

  def placeholder_stat(assigns) do
    ~H"""
    <div class="btn btn-outline group border-base-content/20 animate-none lg:stat lg:border-base-content/20 lg:h-auto lg:text-left">
      <div class="truncate leading-4 lg:stat-title lg:group-hover:text-base-100/80">
        {@title}
      </div>
      <div class={["stat-value max-lg:hidden"]}>
        <div class="skeleton my-2 h-6 w-24"></div>
      </div>
      <div class={["stat-desc max-lg:hidden lg:group-hover:text-base-100/80"]}>
        <div class="skeleton max-w-32 h-4"></div>
      </div>
    </div>
    """
  end

  attr :state, :atom,
    required: true,
    values: [
      :not_published,
      :publishing,
      :in_publication,
      :published,
      :publication_failed,
      :stale
    ]

  attr :tooltip, :boolean, default: true

  def publication_state_badge(assigns) do
    assigns =
      assigns
      |> assign(:name, :update_fast_track_status)
      |> assign(:content, %{"fast_track_status" => Atom.to_string(assigns.state)})

    ~H"""
    <.badge
      class={if @tooltip, do: "tooltip", else: nil}
      color={ActivityFeed.badge_color(@name, @content)}
      data-tip={if @tooltip, do: ActivityFeed.icon_tooltip(@name, @content), else: nil}
    >
      <.icon name={ActivityFeed.icon_lookup(@name, @content)} class="size-5 shrink-0" />
      <span class="text-nowrap pr-1.5">
        {ActivityFeed.badge_text(@name, @content)}
      </span>
    </.badge>
    """
  end

  attr :state, :atom,
    required: true,
    values: [
      :not_validated,
      :validating,
      :in_validation,
      :validated,
      :validation_failed,
      :stale
    ]

  attr :tooltip, :boolean, default: true

  def validation_state_badge(assigns) do
    assigns =
      assigns
      |> assign(:name, :update_validation_status)
      |> assign(:content, %{"validation_status" => Atom.to_string(assigns.state)})

    ~H"""
    <.badge
      class={if @tooltip, do: "tooltip", else: nil}
      color={ActivityFeed.badge_color(@name, @content)}
      data-tip={if @tooltip, do: ActivityFeed.icon_tooltip(@name, @content), else: nil}
    >
      <.icon name={ActivityFeed.icon_lookup(@name, @content)} class="size-5 shrink-0" />
      <span class="text-nowrap pr-1.5">
        {ActivityFeed.badge_text(@name, @content)}
      </span>
    </.badge>
    """
  end

  attr :center, :string, required: true

  def swiss_species_center_badge(assigns) do
    ~H"""
    <.badge
      class="tooltip"
      color={swiss_species_color(@center)}
      data-tip={swiss_species_tooltip(@center)}
    >
      <.icon name={swiss_species_icon_name(@center)} />
      <span class="text-nowrap pr-1.5">
        {swiss_species_text(@center)}
      </span>
    </.badge>
    """
  end

  def swiss_species_text(nil), do: ~t"Unknown"m
  def swiss_species_text("_not_registered"), do: ~t"Not registered"m
  def swiss_species_text(center), do: center

  defp swiss_species_color(nil), do: "gray"
  defp swiss_species_color("_not_registered"), do: "blue"
  defp swiss_species_color(_center), do: "green"

  defp swiss_species_icon_name(nil), do: "hero-question-mark-circle-solid"
  defp swiss_species_icon_name("_not_registered"), do: "hero-information-circle-solid"
  defp swiss_species_icon_name(_center), do: "hero-check-circle-solid"

  defp swiss_species_tooltip(nil),
    do:
      ~t"There is no information about whether this species has been registered by a Swiss species data center. Please run the ‘Encoding’ to update the information."m

  defp swiss_species_tooltip("_not_registered"),
    do: ~t"This species has not been registered by any Swiss species data center"m

  defp swiss_species_tooltip(center),
    do: mgettext("This species has been registered by the Swiss species data center %{center}", center: center)

  @level [0, 1, 2, 3, 4]

  attr :level, :integer, required: true, values: @level

  def mids_level_indicator(assigns) do
    color_dot_range = Range.new(1, assigns.level)
    gray_dot_range = Range.new(1, 4 - assigns.level)

    assigns = assign(assigns, :color_dot_range, color_dot_range)
    assigns = assign(assigns, :gray_dot_range, gray_dot_range)

    ~H"""
    <div
      class={[
        "tooltip tooltip-top max-w-32 flex h-8 cursor-help justify-evenly rounded-full p-2",
        level_indicator(@level)
      ]}
      data-tip={level_translation(@level)}
    >
      <div :for={_level <- @color_dot_range} :if={@level > 0}>
        <div class="size-4 rounded-full bg-current" />
      </div>
      <div :for={_level <- @gray_dot_range} :if={@level < 4}>
        <div class="bg-base-100 size-4 rounded-full " />
      </div>
    </div>
    """
  end

  attr :associated_media, :string, required: true
  attr :class, :string, default: ""

  def first_associated_media(%{associated_media: nil} = assigns), do: ~H""

  def first_associated_media(%{associated_media: associated_media} = assigns) do
    split =
      associated_media
      |> String.split("|")
      |> Enum.map(&String.trim/1)

    assigns = assign(assigns, :split, split)

    ~H"""
    <div class={@class}>
      <img src={List.first(@split)} class="max-h-128 w-2/3 rounded-lg px-8" />
    </div>
    """
  end

  attr :text, :string, required: true
  attr :gbif_id, :string, default: nil
  attr :fast_track_status, :atom, default: nil

  def slideover_subtitle(assigns) do
    ~H"""
    <div class="my-auto flex space-x-3">
      <p class="text-base-content/60 text-sm/6 line-clamp-2 mt-1 max-w-4xl">
        {@text}
      </p>
      <.link
        :if={@gbif_id !== nil && @fast_track_status == :published}
        class="link link-primary link-hover text-sm/6 mt-1 flex max-w-4xl items-center gap-x-2"
        target="_blank"
        href={"#{gbif_base_url()}/occurrence/#{@gbif_id}"}
      >
        {~t"Show on GBIF"} <.icon name="hero-arrow-top-right-on-square" class="size-4" />
      </.link>
    </div>
    """
  end

  defp level_indicator(level) do
    gray = "bg-base-300 text-base-content/60 border border-black-white/20"
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
        ~t"Record has a top quality. Add more data fields to improve your datasets relevance"m
    end
  end
end
