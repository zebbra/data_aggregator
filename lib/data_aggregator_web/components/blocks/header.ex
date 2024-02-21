defmodule DataAggregatorWeb.Blocks.Header do
  @moduledoc """
  Header component.
  """

  use Phoenix.Component

  @doc """
  Renders a header with title, subtitle, breadcrumbs, secondary navigation, and actions.
  """
  attr(:class, :string, default: nil, doc: "the header class")
  attr(:action_class, :string, default: nil)
  attr(:dense, :boolean, default: false, doc: "whether to use a dense layout")

  attr(:break, :boolean,
    default: false,
    doc: "whether to break the header actions into a new line on small screens"
  )

  slot(:navbar, doc: "the optional navbar displayed above the title")
  slot(:breadcrumbs, doc: "the optional breadcrumbs displayed above the title")
  slot(:inner_block, required: true, doc: "the title of the header")
  slot(:subtitle, doc: "the optional subtitle displayed below the title")
  slot(:actions, doc: "the optional actions displayed on the right side of the header")

  def header(assigns) do
    ~H"""
    <header class={["w-full", @class]}>
      <div class={!@dense && "p-6 lg:px-8"}>
        <div class={[
          @break && "sm:flex sm:items-start sm:justify-between sm:gap-8",
          @break == false && "flex items-start justify-between gap-6 sm:gap-8"
        ]}>
          <div class="min-w-0 flex-1">
            <%= render_slot(@breadcrumbs) %>
            <div class="min-h-12">
              <h1 class="text-base-content text-lg/6 truncate font-semibold">
                <%= render_slot(@inner_block) %>
              </h1>
              <p :if={@subtitle != []} class="text-base-content/50 text-sm/6 line-clamp-3">
                <%= render_slot(@subtitle) %>
              </p>
            </div>
          </div>
          <div class={["flex gap-x-3", @break && "max-sm:mt-4", @action_class]}>
            <%= render_slot(@actions) %>
          </div>
        </div>
      </div>
      <%= render_slot(@navbar) %>
    </header>
    """
  end

  attr :class, :string, default: nil, doc: "the header class"
  attr :title, :string, required: true, doc: "the title of the header"
  attr :subtitle, :string, default: nil, doc: "the optional subtitle of the header"

  attr :size, :string,
    values: ["xs", "sm", "lg", "xl"],
    default: "lg",
    doc: "the size of the title"

  slot :actions, doc: "the optional actions displayed on the right side of the header"

  def heading(assigns) do
    ~H"""
    <div class={["w-full sm:flex sm:items-baseline sm:justify-between", @class]}>
      <div class="sm:w-0 sm:flex-1">
        <h4 class={["text-base-content font-bold", heading_title_size_class(@size)]}>
          <%= @title %>
        </h4>
        <p :if={@subtitle} class={["text-base-content/50", heading_subtitle_size_class(@size)]}>
          <%= @subtitle %>
        </p>
      </div>
      <div
        :if={@actions != []}
        class="mt-4 flex items-center justify-between gap-x-3 sm:mt-0 sm:ml-6 sm:flex-shrink-0 sm:flex-row-reverse sm:justify-start"
      >
        <%= render_slot(@actions) %>
      </div>
    </div>
    """
  end

  defp heading_title_size_class(size) do
    case size do
      "xs" -> "text-xs"
      "sm" -> "text-sm"
      "lg" -> "text-lg"
      "xl" -> "text-xl"
    end
  end

  defp heading_subtitle_size_class(size) do
    case size do
      "xs" -> "text-xs"
      "sm" -> "text-sm"
      "lg" -> "text-sm"
      "xl" -> "text-sm"
    end
  end
end
