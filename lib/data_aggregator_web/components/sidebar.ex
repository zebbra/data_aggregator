defmodule DataAggregatorWeb.Components.Sidebar do
  @moduledoc """
  Renders a sidebar with header, inner_block, and footer slots with default tailwindui style.
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a sidebar with header, inner_block, and footer slots with default tailwindui style.
  """
  attr :class, :string, default: nil, doc: "the sidebar class"
  attr :as, :string, default: "div"

  slot :inner_block, required: true
  slot :header, doc: "the optional header slot, displayed sticky at top"
  slot :footer, doc: "the optional footer slot, displayed sticky at bottom"

  def sidebar(assigns) do
    ~H"""
    <.dynamic_tag
      name={@as}
      class={[
        "flex flex-col h-full bg-gray-100/30 dark:bg-black/10 shadow-xl border-l border-b border-gray-200 dark:border-white/10 divide-y divide-gray-200 dark:divide-white/5",
        @class
      ]}
    >
      <div class="overscroll-contain no-scrollbar flex flex-col flex-1 min-h-0 pb-6 overflow-y-scroll">
        <%= render_slot(@header) %>
        <div class="relative flex-1">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
      <div
        :if={@footer != []}
        class="dark:bg-gray-900 flex justify-end flex-shrink-0 px-4 py-4 bg-white"
      >
        <%= render_slot(@footer) %>
      </div>
    </.dynamic_tag>
    """
  end
end
