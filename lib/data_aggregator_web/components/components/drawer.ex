defmodule DataAggregatorWeb.Components.Drawer do
  @moduledoc """
  Drawer components.
  """

  use Phoenix.Component

  @doc """
  Renders a drawer. Checkout the [drawer documentation](https://daisyui.com/components/drawer) for more information.

  ## Examples

      <.drawer
        id="drawer-right"
        class="drawer-end"
        overlay
      >
        <section>
          <label
            aria-label="Open drawer"
            for="drawer-right"
            class="btn btn-square btn-ghost drawer-button"
          >
            <.icon name="hero-bars-3-mini" class="size-5 md:size-6" />
          </label>
          Main content
        </section>
        <:side>
          <div class="bg-base-100 border-black-white/10 min-h-screen w-80 border-l p-4">
            Sidebar content
          </div>
        </:side>
      </.drawer>
  """
  attr(:id, :string, required: true, doc: "ID of the drawer")
  attr(:class, :string, default: nil, doc: "Class to add to the drawer")
  attr(:content_class, :string, default: nil, doc: "Class to add to the drawer content")
  attr(:side_class, :string, default: nil, doc: "Class to add to the side content")
  attr(:overlay, :boolean, default: false, doc: "Whether to show an overlay or not")
  attr(:checked, :boolean, default: nil, doc: "Manually set the drawer to be open or not")

  slot(:inner_block, required: true, doc: "Actual content of the drawer")
  slot(:side, required: true, doc: "Sidebar wrapper")

  def drawer(assigns) do
    ~H"""
    <div class={["drawer", @overlay == false && "fix-drawer-pointer-events", @class]}>
      <input id={@id} type="checkbox" class="drawer-toggle" checked={@checked} />
      <div class={["drawer-content", @content_class]}>
        <%= render_slot(@inner_block) %>
      </div>
      <aside class={["drawer-side z-10", @side_class]}>
        <label :if={@overlay} for={@id} class="drawer-overlay" aria-label={"Close #{@id}"} />
        <%= render_slot(@side) %>
      </aside>
    </div>
    """
  end
end
