defmodule DataAggregatorWeb.HeadlessComponents do
  @moduledoc """
  Common headless components so that we do not have to redefine default
  classes and transitions each time we use them.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Headless.Menu
  import DataAggregatorWeb.Headless.Switch
  import DataAggregatorWeb.Headless.Dialog
  import DataAggregatorWeb.CoreComponents, only: [icon: 1, button: 1]

  @doc ~S"""
  Renders a switch group component. Used to build switches with labes and descriptions.

  Uses `headless_switch_group` internally.

  ## Examples

      <.switch_group id="switch__group" class="flex items-center justify-between">
        <span class="flex flex-col flex-grow">
          <.switch_label
            id="switch__label"
            as="span"
            class="text-sm font-medium leading-6 text-gray-900"
          >
            Available to hire
          </.switch_label>
          <.switch_description id="switch__description" as="span" class="text-sm text-gray-500">
            Nulla amet tempus sit accumsan. Aliquet turpis sed sit lacinia.
          </.switch_description>
        </span>
        <.switch id="switch" checked />
      </.switch_group>
  """

  attr :id, :string,
    required: true,
    doc: "the id of the switch group (must conform <switch.id>__group)"

  attr :as, :string, default: "div"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_group(assigns) do
    ~H"""
    <.headless_switch_group id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_group>
    """
  end

  @doc ~S"""
  Renders a switch component. Used to build switches with labes and descriptions.

  Uses `headless_switch` internally.
  """

  attr :id, :string, required: true
  attr :as, :string, default: "button"
  attr :checked, :boolean, default: false, doc: "the checked state of the switch"
  attr :value, :string, default: "on", doc: "the checked value of the switch"
  attr :name, :string, default: nil, doc: "the field name of the switch if used inside a form"

  attr :class, :string,
    default:
      "bg-gray-200 group aria-checked:bg-indigo-600 w-11 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 relative inline-flex flex-shrink-0 h-6 transition-colors duration-200 ease-in-out border-2 border-transparent rounded-full cursor-pointer",
    doc: "the class of the switch"

  attr :rest, :global

  slot :inner_block

  def switch(assigns) do
    ~H"""
    <.headless_switch
      id={@id}
      as={@as}
      checked={@checked}
      value={@value}
      name={@name}
      class={@class}
      {@rest}
    >
      <%= render_slot(@inner_block) || default_switch(assigns) %>
    </.headless_switch>
    """
  end

  defp default_switch(assigns) do
    ~H"""
    <span class="sr-only">Use setting</span>
    <span class="group-aria-checked:translate-x-5 ring-0 relative inline-block w-5 h-5 transition duration-200 ease-in-out transform translate-x-0 bg-white rounded-full shadow pointer-events-none">
      <span
        class="group-aria-checked:opacity-0 group-aria-checked:duration-100 group-aria-checked:ease-out absolute inset-0 flex items-center justify-center w-full h-full transition-opacity duration-200 ease-in opacity-100"
        aria-hidden="true"
      >
        <svg class="w-3 h-3 text-gray-400" fill="none" viewBox="0 0 12 12">
          <path
            d="M4 8l2-2m0 0l2-2M6 6L4 4m2 2l2 2"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
      </span>
      <span
        class="group-aria-checked:opacity-100 group-aria-checked:duration-200 group-aria-checked:ease-in absolute inset-0 flex items-center justify-center w-full h-full transition-opacity duration-100 ease-out opacity-0"
        aria-hidden="true"
      >
        <svg class="w-3 h-3 text-indigo-600" fill="currentColor" viewBox="0 0 12 12">
          <path d="M3.707 5.293a1 1 0 00-1.414 1.414l1.414-1.414zM5 8l-.707.707a1 1 0 001.414 0L5 8zm4.707-3.293a1 1 0 00-1.414-1.414l1.414 1.414zm-7.414 2l2 2 1.414-1.414-2-2-1.414 1.414zm3.414 2l4-4-1.414-1.414-4 4 1.414 1.414z" />
        </svg>
      </span>
    </span>
    """
  end

  @doc ~S"""
  Renders a switch label component. Used to build switches with labes and descriptions.

  Uses `headless_switch_label` internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the switch label (must conform <switch.id>__label)"

  attr :passive, :boolean,
    default: false,
    doc:
      "set to true if you want to use the switch label as a passive label which does not toggle the switch"

  attr :as, :string, default: "label"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_label(assigns) do
    ~H"""
    <.headless_switch_label id={@id} as={@as} passive={@passive} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_label>
    """
  end

  @doc ~S"""
  Renders a switch description component. Used to build switches with labes and descriptions.

  Uses `headless_switch_description` internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the switch description (must conform <switch.id>__description)"

  attr :as, :string, default: "p"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_description(assigns) do
    ~H"""
    <.headless_switch_description id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_description>
    """
  end

  @doc ~S"""
  Menu component for dropdowns with tailwindui style.

  Uses the `headless_menu` component internally.

  ## Examples

      <.menu id="menu">
        <.menu_button id="menu__button">
          Menu 1
        </.menu_button>
        <.menu_items id="menu__items">
          <%= for {_key, items} <- @items do %>
            <div class="py-1" role="none">
              <%= for item <- items do %>
                <.menu_item id={"menu__item-#{item.id}"} patch="#" disabled={item.disabled}>
                  <.icon
                    name={item.icon}
                    class="group-hover:text-gray-500 w-5 h-5 mr-3 text-gray-400"
                  />
                  <span><%= item.name %></span>
                </.menu_item>
              <% end %>
            </div>
          <% end %>
        </.menu_items>
      </.menu>
  """

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: "relative inline-block text-left", doc: "the class of the menu"

  attr :hide_transition, :map,
    default:
      {"transition ease-in duration-75", "transform opacity-100 scale-100",
       "transform opacity-0 scale-95"},
    doc: "the transition for hiding the menu"

  attr :rest, :global

  slot :inner_block, required: true

  def menu(assigns) do
    ~H"""
    <.headless_menu id={@id} as={@as} class={@class} hide_transition={@hide_transition} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu>
    """
  end

  @doc ~S"""
  Menu button component for dropdowns with tailwindui style.

  Uses the `headless_menu_button` component internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the menu button (must conform <menu.id>__button)"

  attr :as, :string, default: "button"

  attr :class, :string,
    default:
      "inline-flex w-full justify-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
    doc: "the class of the menu button"

  attr :show_transition, :map,
    default:
      {"transition ease-out duration-100", "transform opacity-0 scale-95",
       "transform opacity-100 scale-100"},
    doc: "the transition for showing the menu"

  attr :rest, :global

  slot :inner_block, required: true

  def menu_button(assigns) do
    ~H"""
    <.headless_menu_button id={@id} as={@as} class={@class} show_transition={@show_transition} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu_button>
    """
  end

  @doc ~S"""
  Menu items component for dropdowns with tailwindui style.

  Uses the `headless_menu_items` component internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the menu items (must conform <menu.id>__items)"

  attr :as, :string, default: "div"

  attr :class, :string,
    default:
      "ring-1 ring-black ring-opacity-5 focus:outline-none absolute right-0 z-50 bg-white divide-y divide-gray-100 rounded-md shadow-lg",
    doc: "the class of the menu items"

  attr :position, :string,
    default: "top-right",
    doc: "the position of the menu items (see position_class/1)"

  attr :width, :string, default: "w-56"
  attr :rest, :global

  slot :inner_block, required: true

  def menu_items(assigns) do
    ~H"""
    <.headless_menu_items
      id={@id}
      as={@as}
      class={Enum.join([@class, position_class(@position)])}
      width={@width}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.headless_menu_items>
    """
  end

  defp position_class(position) do
    case position do
      "bottom-right" -> "origin-bottom-right mb-11 bottom-0"
      _ -> "origin-top-right mt-2"
    end
  end

  @doc ~S"""
  Menu item component for dropdowns with tailwindui style.

  Uses the `headless_menu_item` component internally.
  """

  attr :id, :string,
    required: true,
    doc: "the id of the menu item (must conform <menu.id>__<item-suffix>)"

  attr :class, :string,
    default:
      "group bg-white aria-selected:bg-gray-100 focus:outline-none aria-selected:text-gray-900 flex justify-between cursor-pointer items-center px-4 py-2 text-sm text-gray-700 w-full"

  attr :rest, :global, include: ~w(navigate patch href replace method csrf_token disabled)
  attr :as, :string, default: nil

  slot :inner_block, required: true

  def menu_item(assigns) do
    ~H"""
    <.headless_menu_item id={@id} as={@as} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu_item>
    """
  end

  @doc ~S"""
  Dialog component for modals with tailwindui style.

  ## Examples

      <.modal
        :if={@live_action in [:new, :edit]}
        id="record-modal"
        on_cancel={JS.patch(~p"/records?#{@current_path_params}")}
      >
        <.live_component
          module={DataAggregatorWeb.RecordLive.FormComponent}
          id={@record.id || :new}
          icon="hero-plus-circle-mini"
          title={@page_title}
          action={@live_action}
          record={@record}
          patch={~p"/records?#{@current_path_params}"}
        />
      </.modal>
  """

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :show, :boolean, default: true, doc: "set to false if you want to use breakpoints"
  attr :class, :string, default: "hidden relative z-50", doc: "the class of the dialog"
  attr :role, :string, default: "dialog", doc: "the role attribute of the dialog"
  attr :backdrop, :boolean, default: true, doc: "set to false if you do not want a backdrop"
  attr :on_cancel, JS, default: %JS{}, doc: "JS callback for the cancel button"
  attr :on_confirm, JS, default: %JS{}, doc: "JS callback for the confirm button"

  attr :show_panel_transition, :map,
    default:
      {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
       "opacity-100 translate-y-0 sm:scale-100"},
    doc: "the transition for showing the panel"

  attr :hide_panel_transition, :map,
    default:
      {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"},
    doc: "the transition for hiding the panel"

  attr :show_backdrop_transition, :map,
    default: {"ease-out duration-300", "opacity-0", "opacity-100"},
    doc: "the transition for showing the backdrop"

  attr :hide_backdrop_transition, :map,
    default: {"ease-in duration-200", "opacity-100", "opacity-0"},
    doc: "the transition for hiding the backdrop"

  attr :rest, :global

  slot :inner_block, required: true

  slot :submit do
    attr :class, :string
  end

  slot :confirm do
    attr :class, :string
  end

  slot :cancel do
    attr :class, :string
  end

  def modal(assigns) do
    ~H"""
    <.dialog
      id={@id}
      as={@as}
      show={@show}
      role={@role}
      class={@class}
      on_cancel={@on_cancel}
      on_confirm={@on_confirm}
      show_panel_transition={@show_panel_transition}
      hide_panel_transition={@hide_panel_transition}
      show_backdrop_transition={@show_backdrop_transition}
      hide_backdrop_transition={@hide_backdrop_transition}
      {@rest}
    >
      <.backdrop :if={@backdrop} id={@id} variant="modal" />

      <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div class="sm:items-center sm:p-0 flex items-end justify-center min-h-full p-4 text-center">
          <.dialog_panel
            id={@id <> "__panel"}
            class="sm:my-8 sm:w-full sm:max-w-lg sm:p-6 dark:bg-gray-900 dark:border dark:border-white/10 relative px-4 pt-5 pb-4 overflow-hidden text-left bg-white rounded-lg shadow-xl"
          >
            <%= render_slot(@inner_block) %>

            <%= if Enum.empty?(@submit) == false || Enum.empty?(@confirm) == false || Enum.empty?(@cancel) == false do %>
              <div class="sm:mt-4 sm:flex sm:flex-row-reverse mt-5">
                <%= for submit <- @submit do %>
                  <.button
                    id={@id <> "__submit"}
                    class={submit[:class] || "sm:ml-3 sm:w-auto inline-flex justify-center w-full"}
                    phx-click={JS.exec("data-apply", to: "##{@id}")}
                    phx-disable-with
                    {assigns_to_attributes(submit)}
                  >
                    <%= render_slot(submit) %>
                  </.button>
                <% end %>
                <%= for confirm <- @confirm do %>
                  <.button
                    id={@id <> "__confirm"}
                    variant="accent"
                    class={confirm[:class] || "sm:ml-3 sm:w-auto inline-flex justify-center w-full"}
                    phx-click={JS.exec("data-apply", to: "##{@id}")}
                    phx-disable-with
                    {assigns_to_attributes(confirm)}
                  >
                    <%= render_slot(confirm) %>
                  </.button>
                <% end %>
                <%= for cancel <- @cancel do %>
                  <.button
                    id={@id <> "__cancel"}
                    variant="secondary"
                    class={
                      cancel[:class] || "mt-3 sm:mt-0 sm:w-auto inline-flex justify-center w-full"
                    }
                    phx-click={JS.exec("data-cancel", to: "##{@id}")}
                    {assigns_to_attributes(cancel)}
                  >
                    <%= render_slot(cancel) %>
                  </.button>
                <% end %>
              </div>
            <% end %>

            <div class="sm:block absolute top-0 right-0 hidden pt-4 pr-4">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:bg-gray-900 text-gray-400 bg-white rounded-md"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark" class="w-6 h-6" />
              </button>
            </div>
          </.dialog_panel>
        </div>
      </div>
    </.dialog>
    """
  end

  @doc ~S"""
  Slideover component for slideovers with tailwindui style.
  """

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :show, :boolean, default: true, doc: "set to false if you want to use breakpoints"
  attr :class, :string, default: "hidden relative z-50", doc: "the class of the dialog"

  attr :width, :string,
    default: "max-w-md",
    doc: "the width of the slideover in tailwindcss format"

  attr :role, :string, default: "dialog", doc: "the role attribute of the dialog"
  attr :backdrop, :boolean, default: true, doc: "set to false if you do not want a backdrop"

  attr :close_button, :boolean,
    default: true,
    doc: "set to false if you do not want a close button"

  attr :breakpoint, :string,
    default: nil,
    doc: "the breakpoint at which the slideover becomes visible / hidden"

  attr :on_cancel, JS, default: %JS{}, doc: "JS callback for the cancel button"
  attr :on_confirm, JS, default: %JS{}, doc: "JS callback for the confirm button"

  attr :show_panel_transition, :map,
    default: {"ease-in-out duration-300", "translate-x-full", "translate-x-0"},
    doc: "the transition for showing the panel"

  attr :hide_panel_transition, :map,
    default: {"ease-in-out duration-300", "translate-x-0", "translate-x-full"},
    doc: "the transition for hiding the panel"

  attr :show_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-0", "opacity-100"},
    doc: "the transition for showing the backdrop"

  attr :hide_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-100", "opacity-0"},
    doc: "the transition for hiding the backdrop"

  attr :rest, :global

  slot :inner_block, required: true

  def slideover(assigns) do
    ~H"""
    <.dialog
      id={@id}
      as={@as}
      show={@show}
      role={@role}
      class={@class}
      on_cancel={@on_cancel}
      on_confirm={@on_confirm}
      display="block"
      breakpoint={@breakpoint}
      show_panel_transition={@show_panel_transition}
      hide_panel_transition={@hide_panel_transition}
      show_backdrop_transition={@show_backdrop_transition}
      hide_backdrop_transition={@hide_backdrop_transition}
      {@rest}
    >
      <.backdrop :if={@backdrop} id={@id} variant="slideover" />

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="fixed inset-y-0 right-0 flex max-w-full pl-10 pointer-events-none">
            <.dialog_panel
              id={@id <> "__panel"}
              slideover
              class={"relative w-screen pointer-events-auto bg-white dark:bg-gray-900 " <> @width}
            >
              <%= render_slot(@inner_block) %>
              <div
                :if={@close_button}
                class="sm:-ml-10 sm:pr-4 absolute top-0 left-0 flex pt-4 pr-2 -ml-8"
              >
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  id={"#{@id}__close"}
                  type="button"
                  class="hover:text-white focus:outline-none focus:ring-2 focus:ring-white relative hidden text-gray-300 rounded-md"
                  aria-label={gettext("close")}
                >
                  <span class="absolute -inset-2.5" />
                  <.icon name="hero-x-mark" class="w-6 h-6 text-white" />
                </button>
              </div>
            </.dialog_panel>
          </div>
        </div>
      </div>
    </.dialog>
    """
  end

  @doc ~S"""
  Slideover component for mobile navigation with tailwindui style.

  ## Examples

      <.mobile_slideover_nav
        :if={@sidebar_nav}
        id="sidebar-nav"
        on_cancel={JS.push("toggle-sidebar-nav")}
      >
        <!-- Sidebar component, swap this element with another sidebar if you like -->
        <.sidebar_nav active_link={@active_link} environment={@environment} />
      </.mobile_slideover_nav>
  """

  attr :id, :string, required: true
  attr :as, :string, default: "div"

  attr :show, :boolean,
    default: true,
    doc: "set to false if you do not want to render the slideover on mount"

  attr :class, :string, default: "hidden relative z-50", doc: "the class of the dialog"

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

  def mobile_slideover_nav(assigns) do
    ~H"""
    <.dialog
      id={@id}
      as={@as}
      show={@show}
      role={@role}
      class={@class}
      on_cancel={@on_cancel}
      on_confirm={@on_confirm}
      display="flex"
      breakpoint="lg:hidden"
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

          <div class="left-full absolute top-0 flex justify-center w-16 pt-5">
            <button
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
              id={"#{@id}__close"}
              type="button"
              class="hidden -m-2.5 p-2.5"
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

  @doc ~S"""
  Backdrop component for modals and slideover components.
  Mostly used internally.
  """

  attr :id, :string, required: true
  attr :variant, :string, default: "modal"

  def backdrop(assigns) do
    ~H"""
    <div
      id={@id <> "__backdrop"}
      class={[
        "hidden fixed inset-0",
        @variant == "slideover" && "bg-black/50 dark:bg-black/40",
        @variant == "modal" && "bg-black/50 dark:bg-black/40"
      ]}
      aria-hidden="true"
    />
    """
  end
end
