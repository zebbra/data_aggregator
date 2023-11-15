defmodule DataAggregatorWeb.Components.List do
  @moduledoc """
  Renders a data list with generic tailwindui styling.
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <dl class="dark:divide-white/5 w-full divide-y divide-gray-200">
      <div :for={item <- @item} class="px-6 py-5">
        <dt class="dark:text-white text-sm font-medium text-gray-500">
          <%= item.title %>
        </dt>
        <dd class="dark:text-gray-200 mt-1 text-sm text-gray-700">
          <%= render_slot(item) %>
        </dd>
      </div>
    </dl>
    """
  end
end
