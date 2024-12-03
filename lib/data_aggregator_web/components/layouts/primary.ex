defmodule DataAggregatorWeb.Layouts.Primary do
  @moduledoc """
  Primary layout component.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Components
  use DataAggregatorWeb, :verified_routes
  use DataAggregatorWeb.Gettext

  alias DataAggregator.Accounts.User

  embed_templates "shared/*"

  @doc """
  Renders the primary layout with a navigation bar on the left side and a main content
  area.

  The primary layout is used to build the main layout of the application. It contains
  the main navigation on the left side and the main content. The main content is
  passed as default slot.

  Modals and dialogs should be placed within the `:portal` slot.

  ## Examples

  ```heex
  <.primary_layout current={@current}>
    <div>
      Content
    </div>
    <:portal>
      <.alert id="alert" size="xs" />
    </:portal>
  </.primary_layout>
  ```
  """
  attr :current, :string, required: true, doc: "Current page"
  attr :current_user, User, default: %User{}, doc: "Current user"

  slot :inner_block, required: true
  slot :portal, doc: "Portal slot for modal, dialog, etc."

  def page(assigns) do
    ~H"""
    <.drawer id="main_navigation_drawer" class="isolate md:drawer-open" overlay>
      <.main {assigns} />

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

  defp version_tag do
    {:ok, vsn} = :application.get_key(:data_aggregator, :vsn)
    List.to_string(vsn)
  end
end
