defmodule DataAggregatorWeb.Components.Modal do
  @moduledoc """
  Renders a modal with generic tailwindui styling.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Backdrop, only: [backdrop: 1]
  import DataAggregatorWeb.Components.Button, only: [button: 1]
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Gettext, only: [gettext: 1]
  import DataAggregatorWeb.Headless.Dialog

  alias Phoenix.LiveView.JS

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
      parent_id={@parent_id}
      as={@as}
      show={@show}
      responsive={@responsive}
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
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <.dialog_panel
            id={@id <> "__panel"}
            class="sm:my-8 sm:w-full sm:max-w-lg sm:p-6 min-w-[calc(100vw-20px)] sm:min-w-fit relative px-4 pt-5 pb-4 overflow-hidden text-left bg-base-100 rounded-lg shadow-xl"
          >
            <%= render_slot(@inner_block) %>

            <%= if Enum.empty?(@submit) == false || Enum.empty?(@confirm) == false || Enum.empty?(@cancel) == false do %>
              <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
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
                    color="accent"
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
                    color="secondary"
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

            <div class="absolute top-0 right-0 hidden pt-4 pr-4 sm:block">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 dark:bg-gray-900"
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
  Renders a header with title, subtitle and actions withing a sidebar.
  """
  attr :modal_id, :string, required: true, doc: "the id of the dialog"
  attr :icon, :string, default: nil, doc: "the icon of the modal"
  attr :title, :string, required: true, doc: "the title of the modal"
  attr :description, :string, default: nil, doc: "the description of the modal"

  def modal_header(assigns) do
    ~H"""
    <div class="sm:flex sm:items-start">
      <div
        :if={assigns[:icon]}
        class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-indigo-100 sm:mx-0 sm:h-10 sm:w-10"
      >
        <.icon name={@icon} class="w-6 h-6 text-indigo-600" />
      </div>
      <div class={["mt-3 text-center sm:mt-0 sm:text-left", assigns[:icon] && "sm:ml-4"]}>
        <.dialog_title
          id={@modal_id <> "__title"}
          class="dark:text-white text-base font-semibold leading-6 text-gray-900"
        >
          <%= @title %>
        </.dialog_title>
        <.dialog_description
          :if={@description != nil}
          id={@modal_id <> "__description"}
          class="dark:text-gray-400 mt-2 text-sm text-gray-500"
        >
          <%= @description %>
        </.dialog_description>
      </div>
    </div>
    """
  end
end
