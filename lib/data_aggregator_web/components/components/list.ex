defmodule DataAggregatorWeb.Components.List do
  @moduledoc """
  List components.
  """

  use Phoenix.Component

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  slot :item, required: true do
    attr(:title, :string, required: true)
  end

  def list(assigns) do
    ~H"""
    <dl class={["divide-base-content/10 w-full divide-y", @class]} {@rest}>
      <div :for={item <- @item} class="px-8 py-5 sm:grid sm:grid-cols-3 sm:gap-4">
        <dt class="text-base-content/90 text-sm/6 font-medium"><%= item.title %></dt>
        <dd class="text-base-content/60 text-sm/6 mt-1 sm:col-span-2 sm:mt-0">
          <%= render_slot(item) %>
        </dd>
      </div>
    </dl>
    """
  end
end
