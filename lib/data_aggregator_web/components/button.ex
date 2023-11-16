defmodule DataAggregatorWeb.Components.Button do
  @moduledoc """
  Renders a button with generic tailwindui styling.
  """

  use Phoenix.Component

  alias DataAggregatorWeb.Components.Icon
  alias DataAggregatorWeb.Components.Loading

  @doc ~S"""
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
      <.button to={~p"/records"} link_type="live_patch" color="secondary">Back</.button>

  """
  attr :size, :string, default: "lg", values: ["xs", "sm", "md", "lg", "xl"], doc: "button sizes"

  attr :variant, :string,
    default: "solid",
    values: ["solid"],
    doc: "button variant"

  attr :color, :string,
    default: "primary",
    values: [
      "primary",
      "secondary",
      "accent",
      "simple"
    ],
    doc: "button color"

  attr :to, :string, default: nil, doc: "link path"
  attr :loading, :boolean, default: false, doc: "indicates a loading state"
  attr :disabled, :boolean, default: false, doc: "indicates a disabled state"
  attr :icon, :string, default: nil, doc: "name of a Heroicon at the front of the button"
  attr :with_icon, :boolean, default: false, doc: "adds some icon base classes"
  attr :responsive, :boolean, default: false, doc: "hides label on small screens"

  attr :type, :string, default: "button", values: ["button", "submit"], doc: "button type"

  attr :link_type, :string,
    default: "button",
    values: ["a", "live_patch", "live_redirect", "button"],
    doc: "link type"

  attr :class, :string, default: "", doc: "CSS class"
  attr :label, :string, default: nil, doc: "labels your button"

  attr :rest, :global,
    include: ~w(method download hreflang ping referrerpolicy rel target type value name form)

  slot :inner_block, required: false

  def button(%{type: "submit"} = assigns) do
    assigns =
      assigns
      |> assign(:classes, button_classes(assigns))

    ~H"""
    <button type="submit" class={@classes} disabled={@disabled} {@rest}>
      <Loading.spinner
        size="xs"
        class={[
          "phx-submit-loading:block",
          if(@loading, do: "block ", else: "hidden"),
          if(@responsive, do: "sm:-ml-0.5 ", else: "-ml-0.5")
        ]}
      />

      <%= if @icon && @loading == false do %>
        <Icon.icon
          name={@icon}
          class={[
            "h-5 w-5 phx-submit-loading:hidden",
            if(@responsive, do: "sm:-ml-0.5 ", else: "-ml-0.5")
          ]}
        />
      <% end %>

      <%= render_slot(@inner_block) || render_label(assigns) %>
    </button>
    """
  end

  def button(assigns) do
    assigns =
      assigns
      |> assign(:classes, button_classes(assigns))

    ~H"""
    <.a to={@to} link_type={@link_type} class={@classes} disabled={@disabled} {@rest}>
      <%= if @loading do %>
        <Loading.spinner
          size="xs"
          class={[
            if(@responsive, do: "sm:-ml-0.5 ", else: "-ml-0.5")
          ]}
        />
      <% else %>
        <%= if @icon do %>
          <Icon.icon
            name={@icon}
            class={[
              "h-5 w-5",
              if(@responsive, do: "sm:-ml-0.5 ", else: "-ml-0.5")
            ]}
          />
        <% end %>
      <% end %>

      <%= render_slot(@inner_block) || render_label(assigns) %>
    </.a>
    """
  end

  defp render_label(assigns) do
    case assigns.responsive do
      true ->
        ~H"""
        <span class="hidden sm:inline-block">
          <%= @label %>
        </span>
        """

      false ->
        ~H"""
        <%= @label %>
        """
    end
  end

  defp button_classes(opts) do
    base_classes = base_classes(opts)
    icon_classes = icon_classes(opts)
    variant_color_classes = variant_color_classes(opts.variant, opts.color)
    size_classes = size_classes(opts.size, opts.color)

    [base_classes, icon_classes, variant_color_classes, size_classes, opts.class]
  end

  defp base_classes(%{type: "submit"} = opts) do
    opts = Map.drop(opts, [:type])

    ["phx-submit-loading:opacity-75 phx-submit-loading:pointer-events-none"] ++
      base_classes(opts)
  end

  defp base_classes(_opts) do
    [
      "select-none font-semibold",
      "disabled:opacity-75 disabled:pointer-events-none"
    ]
  end

  defp icon_classes(%{type: "submit"} = opts) do
    opts = Map.drop(opts, [:type])

    base =
      if opts.loading,
        do: [],
        else: [
          "phx-submit-loading:inline-flex phx-submit-loading:items-center phx-submit-loading:whitespace-nowrap"
        ]

    case opts.size do
      "xl" -> ["phx-submit-loading:gap-x-2"] ++ base ++ icon_classes(opts)
      _ -> ["phx-submit-loading:gap-x-1.5"] ++ base ++ icon_classes(opts)
    end
  end

  defp icon_classes(opts) do
    with_icon = opts.with_icon || opts.icon || opts.loading || false

    if with_icon do
      case opts.size do
        "xl" -> ["inline-flex items-center gap-x-2 whitespace-nowrap"]
        _ -> ["inline-flex items-center gap-x-1.5 whitespace-nowrap"]
      end
    else
      []
    end
  end

  defp variant_color_classes(variant, color) do
    case [variant, color] do
      ["solid", "primary"] ->
        [
          "text-white bg-indigo-600 hover:bg-indigo-500 shadow-sm",
          "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
          "dark:bg-indigo-500 dark:hover:bg-indigo-400",
          "dark:focus-visible:outline-indigo-500"
        ]

      ["solid", "secondary"] ->
        [
          "text-gray-900 bg-white hover:bg-gray-50 shadow-sm",
          "ring-1 ring-inset ring-gray-300",
          "dark:text-white dark:ring-0",
          "dark:bg-white/10 dark:hover:bg-white/20"
        ]

      ["solid", "accent"] ->
        [
          "text-white bg-red-600 hover:bg-red-500 shadow-sm",
          "dark:bg-red-500 dark:hover:bg-red-400"
        ]

      ["solid", "simple"] ->
        [
          "leading-6",
          "text-indigo-600 hover:text-indigo-900",
          "dark:text-indigo-400 dark:hover:text-indigo-300"
        ]
    end
  end

  defp size_classes(size, "simple") do
    case size do
      "xs" -> "text-xs"
      _ -> "text-sm"
    end
  end

  defp size_classes(size, _color) do
    case size do
      "xs" -> "px-2 py-1 text-xs rounded"
      "sm" -> "px-2 py-1 text-sm rounded"
      "md" -> "px-2.5 py-1.5 text-sm rounded-md"
      "lg" -> "px-3 py-2 text-sm rounded-md"
      "xl" -> "px-3.5 py-2.5 text-sm rounded-md"
      _ -> nil
    end
  end

  attr :class, :any, default: "", doc: "CSS class for link (either a string or list)"
  attr :link_type, :string, default: "a", values: ["a", "live_patch", "live_redirect", "button"]
  attr :label, :string, default: nil, doc: "label your link"
  attr :to, :string, default: nil, doc: "link path"

  attr :disabled, :boolean,
    default: false,
    doc: "disables the link. This will turn an <a> into a <button> (<a> tags can't be disabled)"

  attr :rest, :global, include: ~w(replace method download)
  slot :inner_block, required: false

  def a(%{link_type: "button", disabled: true} = assigns) do
    assigns = update_in(assigns.rest, &Map.drop(&1, [:"phx-click"]))

    ~H"""
    <button type="button" class={@class} disabled={@disabled} {@rest}>
      <%= if @label, do: @label, else: render_slot(@inner_block) %>
    </button>
    """
  end

  # Since the <a> tag can't be disabled, we turn it into a disabled button
  # (looks exactly the same and does nothing when clicked)
  def a(%{disabled: true, link_type: type} = assigns) when type != "button" do
    a(Map.put(assigns, :link_type, "button"))
  end

  def a(%{link_type: "a"} = assigns) do
    ~H"""
    <.link href={@to} class={@class} {@rest}>
      <%= if(@label, do: @label, else: render_slot(@inner_block)) %>
    </.link>
    """
  end

  def a(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <.link patch={@to} class={@class} {@rest}>
      <%= if(@label, do: @label, else: render_slot(@inner_block)) %>
    </.link>
    """
  end

  def a(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <.link navigate={@to} class={@class} {@rest}>
      <%= if(@label, do: @label, else: render_slot(@inner_block)) %>
    </.link>
    """
  end

  def a(%{link_type: "button"} = assigns) do
    ~H"""
    <button type="button" class={@class} disabled={@disabled} {@rest}>
      <%= if @label, do: @label, else: render_slot(@inner_block) %>
    </button>
    """
  end
end
