defmodule DataAggregatorWeb.Components.Flash do
  @moduledoc """
  Flash components.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Button, only: [close_button: 1]
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Components.Transitions, only: [show: 1, hide: 1, hide: 2]
  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

  ```heex
  <.flash kind={:info} flash={@flash} />
  <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  ```
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :close, :boolean, default: true, doc: "whether to show the close button"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"
  attr :stretch, :boolean, default: false, doc: "whether the flash should be full width"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "bg-base-100",
        "pointer-events-auto",
        "relative",
        "w-full",
        @stretch == false && "max-w-sm",
        "rounded-xl"
      ]}
      class="bg-base-100 pointer-events-auto relative w-full rounded-xl"
      {@rest}
    >
      <div class={[
        "alert overflow-hidden",
        @kind == :info && "alert-success text-success bg-success/10 border-success/20",
        @kind == :error && "alert-error text-error bg-error/10 border-error/20"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="size-6" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="size-6" />

        <div>
          <h3 :if={@title} class="font-medium">
            <%= @title %>
          </h3>
          <div class="text-sm">
            <%= msg %>
          </div>
        </div>

        <.close_button
          :if={@close}
          dense
          class={
            class_names([
              @kind == :info && "text-success hover:bg-success/20",
              @kind == :error && "text-error hover:bg-error/20"
            ])
          }
          squared
          icon_class=""
          on_cancel={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
        />
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :class, :string, default: nil, doc: "the flash group class"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} class={@class}>
      <div
        aria-live="assertive"
        class="pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6"
      >
        <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
          <.flash kind={:info} title={~t"Success!"m} flash={@flash} />
          <.flash kind={:error} title={~t"Error!"m} flash={@flash} />
          <.flash
            id="client-error"
            kind={:error}
            title={~t"We can't find the internet"m}
            phx-disconnected={show(".phx-client-error #client-error")}
            phx-connected={hide("#client-error")}
            hidden
          >
            <%= ~t"Attempting to reconnect"m %>
            <.icon name="hero-arrow-path" class="ml-1 size-3 animate-spin" />
          </.flash>

          <.flash
            id="server-error"
            kind={:error}
            title={~t"Something went wrong!"m}
            phx-disconnected={show(".phx-server-error #server-error")}
            phx-connected={hide("#server-error")}
            hidden
          >
            <%= ~t"Hang in there while we get back on track"m %>
            <.icon name="hero-arrow-path" class="ml-1 size-3 animate-spin" />
          </.flash>
        </div>
      </div>
    </div>
    """
  end
end
