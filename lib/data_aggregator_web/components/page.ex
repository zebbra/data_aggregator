defmodule DataAggregatorWeb.Page do
  @moduledoc false

  use Phoenix.Component

  # Core UI components and translation
  import DataAggregatorWeb.CoreComponents, only: [icon: 1]
  import DataAggregatorWeb.HeadlessComponents
  import DataAggregatorWeb.Gettext

  # Shortcut for generating JS commands
  alias Phoenix.LiveView.JS

  use DataAggregatorWeb, :verified_routes

  embed_templates "shared/*"

  attr :environment, :atom, required: true
  attr :active_link, :atom, required: true
  attr :sidebar_nav, :boolean, default: false

  attr :class, :string, default: nil
  attr :rest, :global

  slot :inner_block, required: true
  slot :portal

  def page(assigns) do
    ~H"""
    <div class="dark:bg-gray-900 no-scrollbar isolate h-screen overflow-y-auto">
      <!-- Static sidebar for desktop -->
      <div class="lg:fixed lg:inset-y-0 lg:z-30 lg:flex lg:w-72 lg:flex-col hidden">
        <.sidebar_nav active_link={@active_link} environment={@environment} />
      </div>
      <%!-- Main content --%>
      <div class="lg:pl-72">
        <.sticky_topbar search={@active_link != :dashboard} sidebar_nav={@sidebar_nav} />
        <main class={@class} {@rest}>
          <%= render_slot(@inner_block) %>
        </main>
      </div>
    </div>

    <div class="isolate" id="headless-portal-root">
      <%!-- Dynamic slideover sidebar nav for mobile --%>
      <.mobile_slideover_nav
        :if={@sidebar_nav}
        id="sidebar-nav"
        on_cancel={JS.push("toggle-sidebar-nav")}
      >
        <!-- Sidebar component, swap this element with another sidebar if you like -->
        <.sidebar_nav active_link={@active_link} environment={@environment} />
      </.mobile_slideover_nav>

      <%!-- All other registered portals --%>
      <%= for portal <- @portal do %>
        <%= render_slot(portal) %>
      <% end %>
    </div>
    """
  end

  def locale_select(assigns) do
    ~H"""
    <div id="locale-select-wrapper" phx-hook="LocaleSelect">
      <.menu id="locale-select">
        <.menu_button
          id="locale-select__button"
          class="dark:bg-gray-900 hover:text-gray-500 dark:hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-600 dark:focus-visible:ring-white focus-visible:ring-offset-2 dark:focus-visible:ring-offset-gray-900 relative flex items-center p-1 text-gray-400 bg-white rounded-full"
        >
          <span class="absolute -inset-1.5" />
          <.icon name="hero-globe-alt" class="w-6 h-6" />
          <span class="px-1"><%= current_locale() %></span>
        </.menu_button>
        <.menu_items id="locale-select__items" width="w-20">
          <div class="py-1" role="none">
            <.menu_item
              :for={locale <- locale_options()}
              as="div"
              id={"locale-select__item-#{locale.id}"}
              phx-click={
                JS.dispatch("set-locale", to: "#locale-select-wrapper", detail: locale[:value])
              }
            >
              <%= locale.label %>
              <span :if={current_locale() == locale.label} class="text-cyan-600 font-bold">
                &check;
              </span>
            </.menu_item>
          </div>
        </.menu_items>
      </.menu>
    </div>
    """
  end

  defp locale_options do
    DataAggregatorWeb.Locale.locales()
    |> Enum.map(fn x ->
      case x do
        "de-CH" -> option("DE", x)
        "fr-CH" -> option("FR", x)
        _ -> option("EN", x)
      end
    end)
  end

  defp option(label, value), do: %{id: value, label: label, value: value}

  defp current_locale do
    case DataAggregatorWeb.Locale.current().cldr_locale_name do
      :"de-CH" -> "DE"
      :"fr-CH" -> "FR"
      _ -> "EN"
    end
  end
end
