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
      |> assign(:name, :update_publication_status)
      |> assign(:content, %{"publication_status" => Atom.to_string(assigns.state)})

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

  attr :registered, :boolean, required: true
  attr :center, :string, required: true

  def swiss_species_center_badge(assigns) do
    ~H"""
    <.badge
      class="tooltip"
      color={swiss_species_color(@registered, @center)}
      data-tip={swiss_species_tooltip(@registered, @center)}
    >
      <.icon name={swiss_species_icon_name(@registered, @center)} />
      <span class="text-nowrap pr-1.5">
        {swiss_species_text(@registered, @center)}
      </span>
    </.badge>
    """
  end

  def swiss_species_text(nil, _center), do: ~t"Unknown"m
  def swiss_species_text(false, _center), do: ~t"Not registered"m
  def swiss_species_text(true, center), do: center

  defp swiss_species_color(nil, _center), do: "gray"
  defp swiss_species_color(false, _center), do: "blue"
  defp swiss_species_color(true, _center), do: "green"

  defp swiss_species_icon_name(nil, _center), do: "hero-question-mark-circle-solid"
  defp swiss_species_icon_name(false, _center), do: "hero-information-circle-solid"
  defp swiss_species_icon_name(true, _center), do: "hero-check-circle-solid"

  defp swiss_species_tooltip(nil, _center),
    do:
      ~t"There is no information about whether this species has been registered by a Swiss species data center. Please run the ‘Encoding’ to update the information."m

  defp swiss_species_tooltip(false, _center),
    do: ~t"This species has not been registered by any Swiss species data center"m

  defp swiss_species_tooltip(true, center),
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

  attr :record, DataAggregator.Records.Record, required: true

  def slideover_subtitle(assigns) do
    ~H"""
    <div class="my-auto flex space-x-3">
      <p class="text-base-content/60 text-sm/6 line-clamp-2 mt-1 max-w-4xl">
        {@record.mte_catalog_number}
      </p>
      <.link
        :if={@record.oth_gbif_id !== nil && @record.publication_status == :published}
        class="link link-primary link-hover text-sm/6 mt-1 flex max-w-4xl items-center gap-x-2"
        target="_blank"
        href={"#{gbif_base_url()}/occurrence/#{@record.oth_gbif_id}"}
      >
        {~t"Show on GBIF"} <.icon name="hero-arrow-top-right-on-square" class="size-4" />
      </.link>

      <.link
        :if={
          @record.collection.code !== nil && @record.mte_catalog_number !== nil &&
            @record.publication_status == :published
        }
        class="link link-primary link-hover text-sm/6 mt-1 flex max-w-4xl items-center gap-x-2"
        target="_blank"
        href={"#{swiss_nat_coll_base_url()}/occurrence/search?catalogNumber=#{@record.mte_catalog_number}&collectionCode=#{@record.collection.code}"}
      >
        {~t"Show on SwissNatColl"} <.icon name="hero-arrow-top-right-on-square" class="size-4" />
      </.link>
    </div>
    """
  end

  attr :record, DataAggregator.Records.Record, required: true
  attr :deletable, :boolean, default: false
  attr :delete_action, :string, default: nil
  attr :rest, :global

  def image_carousel(assigns) do
    images = build_carousel_items(assigns.record)

    assigns = assign(assigns, images: images)

    ~H"""
    <div class="carousel space-x-4">
      <div :for={{image, _index} <- @images} class="carousel-item relative" id={"item-#{image.id}"}>
        <img src={image.image_url} class="max-h-[350px] w-auto" />
        <button
          :if={@deletable}
          class="btn tooltip tooltip-left btn-sm btn-circle btn-ghost absolute right-3 bottom-3 inline-flex bg-black"
          phx-click={JS.push(@delete_action, value: %{id: image.id})}
          {@rest}
        >
          <.icon name="hero-trash-mini" class="size-5" />
        </button>
      </div>
    </div>
    <div class="flex w-full justify-center gap-2 py-2">
      <a
        :for={{image, index} <- @images}
        :if={length(@images) > 1}
        href={"#item-#{image.id}"}
        class="btn btn-xs"
      >
        {index + 1}
      </a>
    </div>
    """
  end

  defp build_carousel_items(record) do
    record = Ash.load!(record, images: :image_url)

    Enum.with_index(record.images)
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
        ~t"No MIDS Level: Not enough metadata available. See the guide for recommendations."m

      1 ->
        ~t"MIDS Level 0 - Bare: Minimal metadata linking a specimen to its digital representation. Consider adding essential details to enhance usability. See the guide for recommendations."m

      2 ->
        ~t"MIDS Level 1 - Basic: Contains fundamental metadata supporting specimen discoverability and management. Additional details will improve scientific value. See the guide for recommendations."m

      3 ->
        ~t"MIDS level 2 - IntermediaryIncludes key scientific data essential for research applications. Adding georeferencing and extended metadata will further enhance its utility. See the guide for recommendations."m

      4 ->
        ~t"MIDS level 3 - Extended: Comprehensive metadata with links to external resources, maximizing interoperability and open data usability."m
    end
  end
end
