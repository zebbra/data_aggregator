defmodule DataAggregatorWeb.Components.Sidebar do
  @moduledoc """
  Renders a sidebar with header, inner_block, and footer slots with default tailwindui style.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Headless.Dialog, only: [dialog_title: 1]

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

  @doc ~S"""
  Renders a header with title, subtitle and actions withing a sidebar.
  """
  attr :sidebar_id, :string, default: nil, doc: "the dialog id"
  attr :class, :string, default: nil, doc: "the header class"
  attr :action_class, :string, default: "flex gap-x-3"

  slot :inner_block, required: true
  slot :subtitle, doc: "the optional subtitle displayed below the title"
  slot :actions, doc: "the optional actions displayed on the right side of the header"

  def sidebar_header(assigns) do
    ~H"""
    <header class={[
      "dark:bg-gray-900 z-10 bg-white border-b dark:border-white/5 border-gray-200 p-4 sm:py-5 sm:px-6 lg:px-8 w-full",
      @actions != [] &&
        "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <.dialog_title
          :if={@sidebar_id}
          id={@sidebar_id <> "__title"}
          class="dark:text-white text-base font-semibold leading-9 text-gray-800"
        >
          <%= render_slot(@inner_block) %>
        </.dialog_title>
        <h1
          :if={!@sidebar_id}
          class="dark:text-white text-base font-semibold leading-9 text-gray-800 outline-none"
        >
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="dark:text-gray-400 mt-2 text-sm leading-6 text-gray-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class={@action_class}><%= render_slot(@actions) %></div>
    </header>
    """
  end
end
