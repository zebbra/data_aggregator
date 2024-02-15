defmodule DataAggregatorWeb.LiveComponents.ThemeSelect do
  @moduledoc """
  A component to select the current color mode.
  """

  use Phoenix.LiveComponent

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]

  @themes [system: "hero-computer-desktop", dark: "hero-moon", light: "hero-sun"]
  @theme_names Keyword.keys(@themes)

  @impl true
  def mount(socket) do
    {theme, _icon} = List.first(@themes)

    socket =
      socket
      |> assign(:themes, @themes)
      |> assign(:current, theme)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      class="btn btn-ghost btn-square text-base-content/75 tooltip tooltip-bottom before:text-xs hover:text-base-content"
      data-tip="Theme"
      phx-click="theme:cycle"
      phx-target={@myself}
      phx-hook="ThemeSelect"
    >
      <div class="swap swap-rotate">
        <.icon :for={{theme, icon} <- @themes} name={icon} class={icon_class(theme, @current)} />
      </div>
    </button>
    """
  end

  defp icon_class(theme, current) do
    class = if theme == current, do: "swap-off", else: "swap-on"
    ["size-6", class]
  end

  def next_theme(current) do
    [{next, _icon}] =
      @themes
      |> Stream.cycle()
      |> Stream.drop_while(fn {theme, _} -> theme != current end)
      |> Stream.drop(1)
      |> Enum.take(1)

    next
  end

  @impl true
  def handle_event("theme:cycle", _params, socket) do
    next = next_theme(socket.assigns.current)

    socket =
      socket
      |> assign(:current, next)
      |> push_event("theme:change", %{theme: next})

    {:noreply, socket}
  end

  def handle_event("theme:current", %{"theme" => theme}, socket) do
    theme = String.to_existing_atom(theme)
    socket = if theme in @theme_names, do: assign(socket, :current, theme), else: socket
    {:noreply, socket}
  end

  @doc """
  Helper method to render the theme selector live component
  """

  attr(:id, :string, default: "theme-selector")

  def theme_select(assigns) do
    ~H"""
    <.live_component id={@id} module={__MODULE__} />
    """
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.LiveComponents.ThemeSelect, only: [theme_select: 1]
    end
  end
end
