defmodule DataAggregatorWeb.Components.List do
  @moduledoc """
  List components.
  """

  use Phoenix.Component

  @doc """
  Renders a data list.

  ## Examples

  ```heex
  <.list>
    <:item title="Title"><%= @post.title %></:item>
    <:item title="Views"><%= @post.views %></:item>
  </.list>
  ```
  """
  attr :class, :string, default: nil, doc: "Additional classes to apply to the list."
  attr :grid_cols, :integer, default: 3, doc: "Number of grid columns."
  attr :dense, :boolean, default: false, doc: "Whether the list should be dense (no padding)."

  attr :dense_vertical, :boolean,
    default: false,
    doc: "Whether the list should be dense vertically (less vertical padding)."

  attr :rest, :global, doc: "The arbitrary HTML attributes to apply to the list tag"

  slot :item, required: true, doc: "The slot for list items." do
    attr :title, :string, required: true, doc: "The title of the list item."
  end

  def list(assigns) do
    ~H"""
    <dl class={["divide-base-content/10 w-full divide-y", @class]} {@rest}>
      <div
        :for={item <- @item}
        class={[
          "py-2 sm:grid-cols-#{@grid_cols} sm:grid sm:gap-4",
          @dense_vertical == false && "py-5",
          @dense == false && "px-6 lg:px-8"
        ]}
      >
        <dt class="text-base-content/90 text-sm/6 font-medium">{item.title}</dt>
        <dd class={["text-base-content/60 text-sm/6 mt-1 sm:col-span-#{@grid_cols - 1} sm:mt-0"]}>
          {render_slot(item)}
        </dd>
      </div>
    </dl>
    """
  end
end
