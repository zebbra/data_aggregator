defmodule DataAggregatorWeb.Components.Flash do
  @moduledoc """
  Renders flash notices with generic tailwindui styling.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Components.Transitions

  @doc ~S"""
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[" pointer-events-auto w-full max-w-sm"]}
      {@rest}
    >
      <div class={[
        "alert overflow-hidden",
        @kind == :info && "alert-success bg-success-content text-success",
        @kind == :error && "alert-error bg-error-content text-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="w-6 h-6 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="w-6 h-6 shrink-0" />

        <div>
          <h3 :if={@title} class="font-medium">
            <%= @title %>
          </h3>
          <div class="text-sm">
            <%= msg %>
          </div>
        </div>

        <div class="ml-4 flex flex-shrink-0">
          <button
            type="button"
            class={[
              "inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2",
              @kind == :info &&
                "bg-green-50 text-green-500 hover:bg-green-100 focus:ring-green-600 focus:ring-offset-green-50",
              @kind == :error &&
                "bg-red-50 text-red-500 hover:bg-red-100 focus:ring-red-600 focus:ring-offset-red-50"
            ]}
            aria-label={gettext("close")}
          >
            <.icon name="hero-x-mark-solid" class="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
    """
  end

  @doc ~S"""
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :class, :string, default: nil, doc: "the flash group class"
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <div
        aria-live="assertive"
        class="pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6"
      >
        <div class="flex w-full flex-col items-center space-y-4 sm:items-end">
          <.flash kind={:info} title={~t"Success!"m} flash={@flash} hidden />
          <.flash kind={:error} title={~t"Error!"m} flash={@flash} hidden />
          <.flash
            id="client-error"
            kind={:error}
            title={~t"We can't find the internet"m}
            phx-disconnected={show(".phx-client-error #client-error")}
            phx-connected={hide("#client-error")}
            hidden
          >
            <%= ~t"Attempting to reconnect"m %>
            <.icon name="hero-arrow-path" class="animate-spin w-3 h-3 ml-1" />
          </.flash>

          <.flash
            id="server-error"
            kind={:error}
            title="Something went wrong!"
            phx-disconnected={show(".phx-server-error #server-error")}
            phx-connected={hide("#server-error")}
            hidden
          >
            <%= ~t"Hang in there while we get back on track"m %>
            <.icon name="hero-arrow-path" class="animate-spin w-3 h-3 ml-1" />
          </.flash>
        </div>
      </div>
    </div>
    """
  end
end
