defmodule DataAggregatorWeb.Layouts.Primary do
  @moduledoc """
  Primary layout component.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Components
  use DataAggregatorWeb, :verified_routes

  import DataAggregatorWeb.Gettext

  embed_templates("shared/*")

  attr(:current, :string, required: true, doc: "Current page")

  slot(:inner_block, required: true)
  slot(:portal, doc: "Portal slot for modal, dialog, etc.")

  def page(assigns) do
    ~H"""
    <.drawer id="main_navigation_drawer" class="isolate md:drawer-open" overlay>
      <.main {assigns} />

      <:side>
        <.main_navigation current={@current} />
      </:side>
    </.drawer>

    <%!-- All registered portals are rendered in an isolated stack--%>
    <div id="portal_root" class="isolate">
      <.alert id="confirm_alert" size="xs" />
      <%= for portal <- @portal do %>
        <%= render_slot(portal) %>
      <% end %>
    </div>
    """
  end

  defp version_tag do
    {:ok, vsn} = :application.get_key(:data_aggregator, :vsn)
    List.to_string(vsn)
  end
end
