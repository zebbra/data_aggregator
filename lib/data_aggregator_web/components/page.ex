defmodule DataAggregatorWeb.Page do
  @moduledoc """
  Shared entrypoint for all pages.
  """

  use Phoenix.Component

  # Core UI components and translation
  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Components.Backdrop, only: [backdrop: 1]
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Components.Menu
  import DataAggregatorWeb.Headless.Dialog, only: [dialog: 1, dialog_panel: 1]

  use DataAggregatorWeb.Components.ThemeSelect

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
    <div class="no-scrollbar bg-base-100 isolate h-screen overflow-y-auto">
      <!-- Static sidebar for desktop -->
      <div class="hidden lg:fixed lg:inset-y-0 lg:z-30 lg:flex lg:w-72 lg:flex-col">
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
      <.menu id="locale-select" width="w-20" class="z-30">
        <:menu_button>
          <.menu_button
            id="locale-select__button"
            class="btn btn-ghost rounded-full text-base-content/75 hover:text-base-content"
          >
            <.icon name="hero-globe-alt" class="w-5 h-5" />
            <%= current_locale() %>
          </.menu_button>
        </:menu_button>

        <div class="z-30 py-1" role="none">
          <.menu_item
            :for={locale <- locale_options()}
            as="div"
            id={"locale-select__item-#{locale.id}"}
            phx-click={
              JS.dispatch("set-locale", to: "#locale-select-wrapper", detail: locale[:value])
            }
          >
            <%= locale.label %>
            <.icon :if={current_locale() == locale.label} name="hero-check-mini" class="w-4 h-4" />
          </.menu_item>
        </div>
      </.menu>
    </div>
    """
  end

  attr :id, :string, required: true

  attr :parent_id, :string,
    default: nil,
    doc: "the id of the parent component if it's a nested dialog"

  attr :as, :string, default: "div"

  attr :show, :boolean,
    default: true,
    doc: "set to false if you do not want to render the slideover on mount"

  attr :class, :string, default: "hidden relative z-10", doc: "the class of the dialog"

  attr :width, :string,
    default: "max-w-xs",
    doc: "the width of the slideover in tailwindcss format"

  attr :role, :string, default: "dialog", doc: "the role attribute of the dialog"
  attr :backdrop, :boolean, default: true, doc: "set to false if you do not want a backdrop"

  attr :close_button, :boolean,
    default: true,
    doc: "set to false if you do not want a close button"

  attr :on_cancel, JS, default: %JS{}, doc: "JS callback for the cancel button"
  attr :on_confirm, JS, default: %JS{}, doc: "JS callback for the confirm button"

  attr :show_panel_transition, :map,
    default: {"ease-in-out duration-300", "-translate-x-full", "translate-x-0"},
    doc: "the transition for showing the panel"

  attr :hide_panel_transition, :map,
    default: {"ease-in-out duration-300", "translate-x-0", "-translate-x-full"},
    doc: "the transition for hiding the panel"

  attr :show_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-0", "opacity-100"},
    doc: "the transition for showing the backdrop"

  attr :hide_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-100", "opacity-0"},
    doc: "the transition for hiding the backdrop"

  attr :rest, :global

  slot :inner_block, required: true

  defp mobile_slideover_nav(assigns) do
    ~H"""
    <.dialog
      id={@id}
      parent_id={@parent_id}
      as={@as}
      show={@show}
      responsive="lg:hidden"
      role={@role}
      class={@class}
      on_cancel={@on_cancel}
      on_confirm={@on_confirm}
      display="flex"
      show_panel_transition={@show_panel_transition}
      hide_panel_transition={@hide_panel_transition}
      show_backdrop_transition={@show_backdrop_transition}
      hide_backdrop_transition={@hide_backdrop_transition}
      {@rest}
    >
      <.backdrop :if={@backdrop} id={@id} variant="slideover" />

      <div class="fixed inset-0 flex">
        <.dialog_panel
          id={@id <> "__panel"}
          slideover
          class="relative flex flex-1 w-full max-w-xs mr-16"
        >
          <%= render_slot(@inner_block) %>

          <div class="absolute top-0 left-full flex w-16 justify-center pt-5">
            <button
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
              id={"#{@id}__close"}
              type="button"
              class="-m-2.5 hidden p-2.5"
              aria-label={gettext("close")}
            >
              <.icon name="hero-x-mark" class="w-6 h-6 text-white" />
            </button>
          </div>
        </.dialog_panel>
      </div>
    </.dialog>
    """
  end

  defp locale_options do
    Enum.map(DataAggregatorWeb.Locale.locales(), fn x ->
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
