defmodule DataAggregatorWeb.Blocks.Slideover do
  @moduledoc """
  Slideover component.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Blocks.Header, only: [header: 1]

  @doc """
  Renders a slideover with a title, subtitle, and actions. The slideover can be
  opened and closed with the `open` attribute. The `on_cancel` attribute is used
  to run JS commands when the slideover is closed.

  Pressing the `Escape` key will close the slideover.
  """

  attr :title, :string, required: true, doc: "the title of the slideover"
  attr :subtitle, :string, default: nil, doc: "the optional subtitle displayed below the title"
  attr :class, :string, default: nil, doc: "the slideover class"
  attr :size, :string, default: "md", values: ~w[sm md lg xl], doc: "the slideover size"

  attr :compact, :boolean,
    default: false,
    doc: "whether the slideover is compact (not min-h-dvh h-full) or not"

  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the slideover is closed."
  attr :open, :boolean, default: false, doc: "whether the slideover is open or not"
  attr :left, :boolean, default: false, doc: "whether the slideover is on the left or not"

  slot :inner_block, required: true, doc: "the inner block of the slideover"
  slot :footer, doc: "the footer of the slideover"

  def slideover(assigns) do
    ~H"""
    <div class={[
      "bg-base-100 border-black-white/10 divide-black-white/10 flex flex-col divide-y",
      !@compact && "min-h-dvh h-full",
      slideover_position_class(@left),
      slideover_size_class(@size)
    ]}>
      <div :if={@open} class="flex min-h-0 flex-1 flex-col overflow-y-scroll pb-6">
        <.header
          dense
          class="sticky top-0 pt-5 pb-6 bg-base-100 z-10 px-6 lg:px-8 border-b border-black-white/10"
        >
          <%= @title %>
          <:subtitle :if={@subtitle}><%= @subtitle %></:subtitle>
          <:actions>
            <button
              class="btn btn-sm btn-circle btn-ghost"
              aria-label={~t"close"m}
              phx-click={@on_cancel}
            >
              ✕
            </button>
          </:actions>
        </.header>

        <div class="relative flex-1 space-y-8 pt-8" phx-window-keydown={@on_cancel} phx-key="Escape">
          <%= render_slot(@inner_block) %>
        </div>
      </div>

      <div :if={@open && @footer != []} class="flex flex-shrink-0 justify-end p-4">
        <%= render_slot(@footer) %>
      </div>
    </div>
    """
  end

  defp slideover_position_class(left) do
    if left, do: "border-r", else: "border-l"
  end

  defp slideover_size_class(size) do
    case size do
      "sm" -> "w-full max-w-sm 3xl:w-[24rem]"
      "md" -> "w-full max-w-md 3xl:w-[28rem]"
      "lg" -> "w-full max-w-lg 3xl:w-[32rem]"
      "xl" -> "w-full max-w-xl 3xl:w-[36rem]"
    end
  end
end
