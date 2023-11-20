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
    <dl class="w-full divide-y divide-gray-200 dark:divide-white/5">
      <div :for={item <- @item} class="px-6 py-5">
        <dt class="text-sm font-medium text-gray-500 dark:text-white">
          <%= item.title %>
        </dt>
        <dd class="mt-1 text-sm text-gray-700 dark:text-gray-200">
          <%= render_slot(item) %>
        </dd>
      </div>
    </dl>
    """
  end
end
