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
      "dark:bg-gray-900 z-10 bg-white border-b dark:border-white/5 border-gray-200 p-4 sm:py-5 sm:px-6 lg:px-8 w-full",
      @actions != [] &&
        "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <h1 class="dark:text-white text-base font-semibold leading-9 text-gray-800 outline-none">
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
