defmodule DataAggregatorWeb.Components.Header do
  @moduledoc """
  Renders a header with title.
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a header with title, subtitle and actions.
  """
  attr :class, :string, default: nil, doc: "the header class"
  attr :action_class, :string, default: "flex gap-x-3"
  attr :id, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle, doc: "the optional subtitle displayed below the title"
  slot :actions, doc: "the optional actions displayed on the right side of the header"

  def header(assigns) do
    ~H"""
    <header class={[
      "z-10 w-full border-b border-gray-200 bg-white p-4 dark:border-white/5 dark:bg-gray-900 sm:px-6 sm:py-5 lg:px-8",
      @actions != [] && "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <h1 class="text-base font-semibold leading-9 text-gray-800 outline-none dark:text-white">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-gray-600 dark:text-gray-400">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class={@action_class}><%= render_slot(@actions) %></div>
    </header>
    """
  end
end
