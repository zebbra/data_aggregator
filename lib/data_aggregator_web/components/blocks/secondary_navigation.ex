defmodule DataAggregatorWeb.Blocks.SecondaryNavigation do
  @moduledoc """
  Secondary navigation component.
  """

  use Phoenix.Component

  @doc """
  Renders a secondary, horizontal navigation which will scroll on small screens.

  ## Example

  ```heex
  <.secondary_navigation class="mt-6">
    <.secondary_navigation_item label="Overview" href="#" active />
    <.secondary_navigation_item label="Details" href="#" />
    <.secondary_navigation_item label="Settings" href="#" />
  </.secondary_navigation>
  ```
  """

  attr :id, :string, default: "secondary_navigation", doc: "ID of the navigation"
  attr :class, :string, default: nil, doc: "Class of the navigation"
  attr :gradient, :boolean, default: true, doc: "Whether to show a gradient on the edges"

  slot :inner_block, required: true, doc: "The navigation items"

  def secondary_navigation(assigns) do
    ~H"""
    <div class={["border-black-white/10 bg-base-200/95 relative z-10 border-y backdrop-blur", @class]}>
      <nav aria-labelledby={@id} class="py-4">
        <h2 id={@id} class="sr-only">Secondary navigation</h2>
        <ul
          role="list"
          class="text-sm/6 text-base-content/75 no-scrollbar flex w-full snap-x scroll-pl-6 items-center gap-x-6 overflow-x-auto font-semibold lg:scroll-pl-8"
        >
          <%= render_slot(@inner_block) %>
        </ul>
      </nav>
      <div
        :if={@gradient}
        class="from-base-200/95 absolute inset-x-0 top-0 h-14 w-6 bg-gradient-to-r"
      />
      <div :if={@gradient} class="from-base-200/95 absolute top-0 right-0 h-14 w-6 bg-gradient-to-l" />
      <div
        :if={@gradient}
        class="from-base-100 top-[calc(3.5rem+1px)] absolute h-6 w-full bg-gradient-to-b"
      />
    </div>
    """
  end

  @doc """
  Renders a secondary navigation item.

  ## Example

  ```heex
  <.secondary_navigation_item label="Overview" href="#" active />
  ```
  """

  attr :label, :string, required: true, doc: "Label of the item"
  attr :href, :string, required: true, doc: "URL of the item"
  attr :active, :boolean, default: false, doc: "Whether the item is active"

  def secondary_navigation_item(assigns) do
    ~H"""
    <li class="snap-start first:pl-6 last:pr-6 lg:first:pl-8 lg:last:pr-8">
      <.link
        navigate={@href}
        class={[
          @active && "text-primary",
          @active == false && "hover:text-base-content"
        ]}
      >
        <%= @label %>
      </.link>
    </li>
    """
  end
end
