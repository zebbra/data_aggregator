defmodule DataAggregatorWeb.Blocks.Header do
  @moduledoc """
  Header component.
  """

  use Phoenix.Component

  @doc """
  Renders a header with title, subtitle, breadcrumbs, secondary navigation, and actions.

  ## Example

  ```heex
  <.page_header title_class="px-6 lg:px-8">
    Hello World
    <:subtitle>I am a header subtitle</:subtitle>
    <:actions>
      <button type="button" class="btn btn-primary max-sm:btn-sm">
        <.icon name="hero-link-mini" /> Link
      </button>
    </:actions>
    <:navbar>
      <.secondary_navigation class="mt-6">
        <.secondary_navigation_item label="Overview" href="#" active />
        <.secondary_navigation_item label="Details" href="#" />
        <.secondary_navigation_item label="Settings" href="#" />
      </.secondary_navigation>
    </:navbar>
  </.page_header>
  ```
  """
  attr :as, :string, default: "h2", doc: "the tag of the title"
  attr :class, :string, default: nil, doc: "the page header class"
  attr :title_class, :string, default: nil, doc: "the title class"
  attr :align_actions, :boolean, default: true, doc: "force the alignment of the actions"

  attr :size, :string,
    default: "2xl",
    values: ~w(sm md lg xl 2xl),
    doc: "the size of the title"

  attr :fixed_min_height, :boolean,
    default: true,
    doc: "force the min-height of the section heading"

  attr :break_at, :string,
    default: "none",
    values: ~w(none sm md lg),
    doc: "the breakpoint at which the section heading actions should break"

  slot :breadcrumbs, doc: "the optional breadcrumbs displayed above the page header" do
    attr :class, :string, doc: "the optinal class for the breadcrumbs"
  end

  slot :inner_block, doc: "the optional default and wrapped title of the page header"

  slot :title, doc: "the optional custom_title of the page header" do
    attr :class, :string, doc: "the optinal class for the title"
  end

  slot :subtitle, doc: "the optional subtitle displayed below the title of the page header" do
    attr :class, :string, doc: "the optional class for the subtitle"
  end

  slot :actions, doc: "the optional actions displayed on the right side of the page header" do
    attr :class, :string, doc: "the optinal class for the action"
  end

  slot :navbar, doc: "the optional secondary navbar displayed below the page header"

  def page_header(assigns) do
    ~H"""
    <header class={["w-full", @class]}>
      <div :for={breadcrumbs <- @breadcrumbs} class={breadcrumbs[:class]}>
        <%= render_slot(breadcrumbs) %>
      </div>

      <.section_heading
        as={@as}
        class={@title_class}
        align_actions={@align_actions}
        size={@size}
        fixed_min_height={@fixed_min_height}
        break_at={@break_at}
      >
        <%= render_slot(@inner_block) %>

        <:title :for={title <- @title} class={title[:class]}>
          <%= render_slot(title) %>
        </:title>

        <:subtitle :for={subtitle <- @subtitle} class={subtitle[:class]}>
          <%= render_slot(subtitle) %>
        </:subtitle>

        <:actions :for={action <- @actions} class={action[:class]}>
          <%= render_slot(action) %>
        </:actions>
      </.section_heading>
      <%= render_slot(@navbar) %>
    </header>
    """
  end

  @doc """
  Renders a section heading with title, subtitle, and actions.

  ## Example

  ```heex
  <.section_heading>
    Hello World
    <:subtitle>I am a section heading subtitle</:subtitle>
    <:actions>
      <button type="button" class="btn btn-primary max-sm:btn-sm">
        <.icon name="hero-link-mini" /> Link
      </button>
    </:actions>
  </.section_heading>
  ```
  """
  attr :as, :string, default: "h4", doc: "the tag of the title"
  attr :text, :string, default: nil, doc: "the optional text (title) of the section heading"

  attr :description, :string,
    default: nil,
    doc: "the optional description (subtitle) of the section heading"

  attr :class, :string, default: nil, doc: "the section heading class"
  attr :align_actions, :boolean, default: false, doc: "force the alignment of the actions"

  attr :align_items, :string,
    default: "baseline",
    values: ~w[center baseline],
    doc: "the alignment of the items"

  attr :size, :string,
    default: "lg",
    values: ~w(sm md lg xl 2xl),
    doc: "the size of the title"

  attr :fixed_min_height, :boolean,
    default: false,
    doc: "force the min-height of the section heading"

  attr :break_at, :string,
    default: "none",
    values: ~w(none sm md lg),
    doc: "the breakpoint at which the section heading actions should break"

  slot :inner_block, doc: "the optional default and wrapped title of the section header"

  slot :title, doc: "the optional custom_title of the section header" do
    attr :class, :string, doc: "the optinal class for the title"
  end

  slot :subtitle, doc: "the optional subtitle displayed below the title of the section header" do
    attr :class, :string, doc: "the optional class for the subtitle"
  end

  slot :actions, doc: "the optional actions displayed on the right side of the section header" do
    attr :class, :string, doc: "the optinal class for the action"
  end

  def section_heading(assigns) do
    ~H"""
    <div class={[
      "w-full",
      @fixed_min_height && "min-h-[33px] sm:min-h-[50px]",
      break_size_class(@break_at, @align_items),
      @class
    ]}>
      <div class={["min-w-0 flex-1", @align_actions && "sm:mt-2"]}>
        <.dynamic_tag
          :if={@title == []}
          tag_name={@as}
          class={[
            "text-base-content max-sm:line-clamp-2 sm:truncate max-w-4xl text-inherit",
            heading_title_size_class(@size)
          ]}
        >
          <%= if @text != nil do %>
            <%= @text %>
          <% else %>
            <%= render_slot(@inner_block) %>
          <% end %>
        </.dynamic_tag>
        <%= if @title != [] do %>
          <%= render_slot(@title) %>
        <% end %>
        <p
          :if={@subtitle != [] || @description != nil}
          class={["text-base-content/60 max-w-4xl", heading_subtitle_size_class(@size)]}
        >
          <%= if @description != nil do %>
            <%= @description %>
          <% else %>
            <%= render_slot(@subtitle) %>
          <% end %>
        </p>
      </div>
      <div
        :for={action <- @actions}
        class={["flex", break_size_action_class(@break_at), action[:class]]}
      >
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end

  defp break_size_class(size, align_items)

  defp break_size_class(size, "baseline") do
    cond do
      size == "none" -> "flex items-baseline justify-between"
      size == "sm" -> "sm:flex sm:items-baseline sm:justify-between"
      size == "md" -> "md:flex md:items-baseline md:justify-between"
      true -> "lg:flex lg:items-baseline lg:justify-between"
    end
  end

  defp break_size_class(size, "center") do
    cond do
      size == "none" -> "flex items-center justify-between"
      size == "sm" -> "sm:flex sm:items-center sm:justify-between"
      size == "md" -> "md:flex md:items-center md:justify-between"
      true -> "lg:flex lg:items-center lg:justify-between"
    end
  end

  defp break_size_action_class(size) do
    cond do
      size == "none" -> "ml-4 flex-shrink-0 justify-start"
      size == "sm" -> "mt-5 sm:mt-0 sm:ml-4 sm:flex-shrink-0 sm:justify-start"
      size == "md" -> "mt-5 md:mt-0 md:ml-4 md:flex-shrink-0 md:justify-start"
      true -> "mt-5 lg:mt-0 lg:ml-4 lg:flex-shrink-0 lg:justify-start"
    end
  end

  defp heading_title_size_class(size) do
    case size do
      "sm" -> "text-sm/5 font-semibold"
      "md" -> "text-base/5 font-bold"
      "lg" -> "text-lg/6 font-bold"
      "xl" -> "text-xl/6 font-bold"
      "2xl" -> "text-2xl font-bold sm:text-3xl sm:tracking-tight"
    end
  end

  defp heading_subtitle_size_class(size) do
    case size do
      "sm" -> "text-sm/5 line-clamp-2"
      "md" -> "text-sm/6 mt-1 line-clamp-2"
      "lg" -> "text-sm/6 mt-1 line-clamp-2"
      "xl" -> "text-sm/6 mt-1 line-clamp-3"
      "2xl" -> "text-sm/6 mt-1 line-clamp-3"
    end
  end
end
