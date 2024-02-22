defmodule DataAggregatorWeb.Components.SlideOver do
  @moduledoc """
  Slideover component for slideovers with tailwindui style.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Backdrop, only: [backdrop: 1]
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Headless.Dialog

  alias Phoenix.LiveView.JS

  @doc ~S"""
  Slideover component for slideovers with tailwindui style.
  """

  attr :id, :string, required: true

  attr :parent_id, :string,
    default: nil,
    doc: "the id of the parent component if it's a nested dialog"

  attr :as, :string, default: "div"

  attr :show, :boolean,
    default: true,
    doc: "set to false if you want to use the responsive feature"

  attr :responsive, :string,
    default: nil,
    doc: "the tailwindcss breakpoint at which the slideover becomes visible / hidden"

  attr :class, :string, default: "hidden relative z-10", doc: "the class of the dialog"

  attr :width, :string,
    default: "sm:max-w-md",
    doc: "the width of the slideover in tailwindcss format"

  attr :role, :string, default: "dialog", doc: "the role attribute of the dialog"
  attr :backdrop, :boolean, default: true, doc: "set to false if you do not want a backdrop"

  attr :close_button, :boolean,
    default: true,
    doc: "set to false if you do not want a close button"

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
      parent_id={@parent_id}
      as={@as}
      show={@show}
      responsive={@responsive}
      role={@role}
      class={@class}
      on_cancel={@on_cancel}
      on_confirm={@on_confirm}
      display="block"
      show_panel_transition={@show_panel_transition}
      hide_panel_transition={@hide_panel_transition}
      show_backdrop_transition={@show_backdrop_transition}
      hide_backdrop_transition={@hide_backdrop_transition}
      {@rest}
    >
      <.backdrop :if={@backdrop} id={@id} variant="slideover" />

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-0 overflow-hidden">
          <div class="pointer-events-none fixed inset-y-0 right-0 flex max-w-full sm:pl-10">
            <.dialog_panel
              id={@id <> "__panel"}
              slideover
              class={"relative w-screen pointer-events-auto bg-white dark:bg-gray-900 " <> @width}
            >
              <%= render_slot(@inner_block) %>
              <div
                :if={@close_button}
                class="absolute top-0 left-0 hidden pt-4 sm:-ml-10 sm:flex sm:pr-4"
              >
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  id={"#{@id}__close"}
                  type="button"
                  class="relative hidden rounded-md text-gray-300 hover:text-white focus:outline-none focus:ring-2 focus:ring-white"
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
end
