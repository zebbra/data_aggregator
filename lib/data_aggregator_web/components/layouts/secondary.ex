defmodule DataAggregatorWeb.Layouts.Secondary do
  @moduledoc """
  Secondary column layout component.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Components
  use DataAggregatorWeb, :verified_routes

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  embed_templates "shared/*"

  attr :current, :string, required: true, doc: "Current page"
  attr :open, :boolean, default: false, doc: "Whether the secondary column is open or not"

  slot :inner_block, required: true
  slot :portal, doc: "Portal slot for modal, dialog, etc."
  slot :secondary, doc: "Aside slot for secondary column"

  def page(assigns) do
    ~H"""
    <.drawer id="sidebar-nav" class="isolate md:drawer-open" side_class="pr-px" overlay>
      <.drawer
        id="secondary-column"
        class={class_names(["drawer-end", @open && "3xl:drawer-open"])}
        side_class="pl-px"
        checked={@open}
      >
        <.main {assigns} />
        <:side>
          <%= render_slot(@secondary) %>
        </:side>
      </.drawer>

      <:side>
        <.sidebar current={@current} />
      </:side>
    </.drawer>

    <%!-- All registered portals are rendered in an isolated stack--%>
    <div id="portal-root" class="isolate">
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
