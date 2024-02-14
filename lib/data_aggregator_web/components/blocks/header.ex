defmodule DataAggregatorWeb.Blocks.Header do
  @moduledoc """
  Header component.
  """

  use Phoenix.Component

  @doc """
  Renders a header with title, subtitle, breadcrumbs, secondary navigation, and actions.
  """
  attr(:class, :string, default: nil, doc: "the header class")
  attr(:action_class, :string, default: "flex mt-5 sm:mt-0 gap-x-3")

  slot(:navbar, doc: "the optional navbar displayed above the title")
  slot(:breadcrumbs, doc: "the optional breadcrumbs displayed above the title")
  slot(:inner_block, required: true, doc: "the title of the header")
  slot(:subtitle, doc: "the optional subtitle displayed below the title")
  slot(:actions, doc: "the optional actions displayed on the right side of the header")

  def header(assigns) do
    ~H"""
    <header class={["min-h-12 w-full", @class]}>
      <%= render_slot(@navbar) %>
      <div class="space-y-2 p-6 lg:px-8">
        <%= render_slot(@breadcrumbs) %>
        <div class="sm:flex sm:items-start sm:justify-between sm:gap-4">
          <div class="min-w-0 flex-1">
            <h1 class="text-base-content text-lg/6 truncate font-semibold">
              <%= render_slot(@inner_block) %>
            </h1>
            <p :if={@subtitle != []} class="text-base-content/50 text-sm/6 line-clamp-3">
              <%= render_slot(@subtitle) %>
            </p>
          </div>
          <%= render_slot(@actions) %>
          <div class={@action_class}><%= render_slot(@actions) %></div>
        </div>
      </div>
    </header>
    """
  end
end
