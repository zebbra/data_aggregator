defmodule DataAggregatorWeb.Blocks.Header do
  @moduledoc """
  Header component.
  """

  use Phoenix.Component

  @doc """
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
    <header class={["w-full", @actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-base-content text-lg/9 font-semibold">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="text-base-content/50 text-sm/6 mt-2">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class={@action_class}><%= render_slot(@actions) %></div>
    </header>
    """
  end
end
