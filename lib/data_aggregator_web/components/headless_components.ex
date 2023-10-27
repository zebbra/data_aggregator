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

  # Switch

  attr :id, :string, required: true
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

  attr :id, :string, required: true
  attr :as, :string, default: "button"
  attr :checked, :boolean, default: false
  attr :value, :string, default: "on"
  attr :form, :string, default: nil
  attr :name, :string, default: nil

  attr :class, :string,
    default:
      "bg-gray-200 aria-checked:bg-indigo-600 w-11 focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 relative inline-flex flex-shrink-0 h-6 transition-colors duration-200 ease-in-out border-2 border-transparent rounded-full cursor-pointer"

  attr :slot_class, :string,
    default:
      "ring-0 group-[.is-checked]/checked:translate-x-5 inline-block w-5 h-5 transition duration-200 ease-in-out transform translate-x-0 bg-white rounded-full shadow pointer-events-none"

  attr :rest, :global

  slot :inner_block

  def switch(assigns) do
    ~H"""
    <.headless_switch
      id={@id}
      as={@as}
      checked={@checked}
      value={@value}
      form={@form}
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
    <span class="sr-only">Toggle</span>
    <span aria-hidden="true" class={@slot_class} />
    """
  end

  attr :id, :string, required: true
  attr :passive, :boolean, default: false
  attr :as, :string, default: "label"
  attr :rest, :global

  slot :inner_block, required: true

  def switch_label(assigns) do
    ~H"""
    <.headless_switch_label id={@id} as={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_switch_label>
    """
  end

  attr :id, :string, required: true
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

  # Menu

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :class, :string, default: "relative inline-block text-left"

  attr :hide_transition, :map,
    default:
      {"transition ease-in duration-75", "transform opacity-100 scale-100",
       "transform opacity-0 scale-95"}

  attr :rest, :global

  slot :inner_block, required: true

  def menu(assigns) do
    ~H"""
    <.headless_menu id={@id} as={@as} class={@class} hide_transition={@hide_transition} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "button"

  attr :class, :string,
    default:
      "inline-flex w-full justify-center gap-x-1.5 rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"

  attr :show_transition, :map,
    default:
      {"transition ease-out duration-100", "transform opacity-0 scale-95",
       "transform opacity-100 scale-100"}

  attr :rest, :global

  slot :inner_block, required: true

  def menu_button(assigns) do
    ~H"""
    <.headless_menu_button id={@id} as={@as} class={@class} show_transition={@show_transition} {@rest}>
      <%= render_slot(@inner_block) %>
    </.headless_menu_button>
    """
  end

  attr :id, :string, required: true
  attr :as, :string, default: "div"

  attr :class, :string,
    default:
      "ring-1 ring-black ring-opacity-5 focus:outline-none absolute right-0 z-50 bg-white divide-y divide-gray-100 rounded-md shadow-lg"

  attr :position, :string, default: "top-right"

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

  attr :id, :string, required: true

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

  # Modal

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :show, :boolean, default: true
  attr :class, :string, default: "hidden relative z-50"
  attr :role, :string, default: "dialog"
  attr :backdrop, :boolean, default: true
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  attr :show_panel_transition, :map,
    default:
      {"ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
       "opacity-100 translate-y-0 sm:scale-100"}

  attr :hide_panel_transition, :map,
    default:
      {"ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
       "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}

  attr :show_backdrop_transition, :map,
    default: {"ease-out duration-300", "opacity-0", "opacity-100"}

  attr :hide_backdrop_transition, :map,
    default: {"ease-in duration-200", "opacity-100", "opacity-0"}

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

  # Slideover

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :show, :boolean, default: true, doc: "set to false if you want to use breakpoints"
  attr :class, :string, default: "hidden relative z-50"
  attr :width, :string, default: "max-w-md"
  attr :role, :string, default: "dialog"
  attr :backdrop, :boolean, default: true
  attr :close_button, :boolean, default: true

  attr :breakpoint, :string,
    default: nil,
    doc: "the breakpoint at which the slideover becomes visible / hidden"

  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  attr :show_panel_transition, :map,
    default: {"ease-in-out duration-300", "translate-x-full", "translate-x-0"}

  attr :hide_panel_transition, :map,
    default: {"ease-in-out duration-300", "translate-x-0", "translate-x-full"}

  attr :show_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-0", "opacity-100"}

  attr :hide_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-100", "opacity-0"}

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

  # Mobile Slideover Navigation

  attr :id, :string, required: true
  attr :as, :string, default: "div"
  attr :show, :boolean, default: true
  attr :class, :string, default: "hidden relative z-50"
  attr :width, :string, default: "max-w-xs"
  attr :role, :string, default: "dialog"
  attr :backdrop, :boolean, default: true
  attr :close_button, :boolean, default: true
  attr :on_cancel, JS, default: %JS{}
  attr :on_confirm, JS, default: %JS{}

  attr :show_panel_transition, :map,
    default: {"ease-in-out duration-300", "-translate-x-full", "translate-x-0"}

  attr :hide_panel_transition, :map,
    default: {"ease-in-out duration-300", "translate-x-0", "-translate-x-full"}

  attr :show_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-0", "opacity-100"}

  attr :hide_backdrop_transition, :map,
    default: {"ease-linear duration-300", "opacity-100", "opacity-0"}

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

  attr :id, :string, required: true
  attr :variant, :string, default: "modal"

  def backdrop(assigns) do
    ~H"""
    <div
      id={@id <> "__backdrop"}
      class={[
        "hidden fixed inset-0",
        @variant == "slideover" && "bg-black/50 dark:bg-gray-400/10",
        @variant == "modal" && "bg-black/50 dark:bg-gray-400/10"
      ]}
      aria-hidden="true"
    />
    """
  end
end
