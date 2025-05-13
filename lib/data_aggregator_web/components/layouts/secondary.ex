defmodule DataAggregatorWeb.Layouts.Secondary do
  @moduledoc """
  Secondary column layout component.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Components
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias DataAggregator.Accounts.User

  embed_templates "shared/*"

  @doc """
  Renders the secondary layout with a navigation bar on the left side, a main content
  area and a drawer on the right side.

  The secondary layout is used to build the main layout of the application. It contains
  the main navigation on the left side, the main content and a drawer on the right side.
  The drawer can be toggled with a button.

  Modals and dialogs should be placed within the `:portal` slot.

  ## Examples

  ```heex
  <.page current="home" open={@show}>
    <.page_header class="px-6 lg:px-8 md:py-6">Dashboard</.page_header>
    <div class="px-6 lg:px-8">
      <button type="button" class="btn btn-primary" phx-click="toggle">
        Toggle secondary
      </button>
    </div>
    <:secondary>
      <div class="bg-base-100 border-black-white/10 min-h-screen w-80 border-l p-4"></div>
    </:secondary>
    <:portal>
      <.alert id="alert" size="xs" />
    </:portal>
  </.page>
  ```

  ```elixir
  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :show, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle", _, socket) do
    socket = update(socket, :show, &(!&1))

    {:noreply, socket}
  end
  ```
  """
  attr :current, :string, required: true, doc: "Current page"
  attr :current_user, User, default: %User{}, doc: "Current user"
  attr :open, :boolean, default: false, doc: "Whether the secondary column is open or not"

  slot :inner_block, required: true
  slot :portal, doc: "Portal slot for modal, dialog, etc."
  slot :secondary, doc: "Aside slot for secondary column"

  def page(assigns) do
    ~H"""
    <.drawer id="main_navigation_drawer" class="isolate md:drawer-open" overlay>
      <.drawer
        id="secondary_column"
        class={class_names(["drawer-end", @open && "3xl:drawer-open"])}
        checked={@open}
      >
        <.main {assigns} />
        <:side>
          {render_slot(@secondary)}
        </:side>
      </.drawer>

      <:side>
        <.main_navigation current={@current} current_user={@current_user} />
      </:side>
    </.drawer>

    <%!-- All registered portals are rendered in an isolated stack--%>
    <div id="portal_root" class="isolate">
      <.alert id="confirm_alert" size="xs" />
      <%= for portal <- @portal do %>
        {render_slot(portal)}
      <% end %>
    </div>

    <%!-- Same as portal_root but meant to be use for components with phx-update="ignore" --%>
    <div id="portal_root_static" phx-update="ignore" class="isolate" />
    """
  end
end
