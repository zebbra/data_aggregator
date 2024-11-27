defmodule DataAggregatorWeb.Components.FuiTooltip do
  @moduledoc """
  Tooltip components that can be used to create a tooltip with floating-ui and
  optional portaling.
  """

  use Phoenix.Component

  attr :id, :string,
    required: true,
    doc: """
    The id for the tooltip. Must match the aria-describedby attribute of the element
    that triggers the tooltip
    """

  attr :class, :string,
    default: nil,
    doc: "Additional CSS classes to style the tooltip"

  attr :visibility_class, :string,
    default: "hidden",
    doc: """
    CSS classes to handle hide/show of the tooltip. See show_class and hide_class
    for more details
    """

  attr :show_class, :string,
    default: "block",
    doc: """
    Class to show the tooltip. Use this in conjunction with the visibility_class to
    show/hide the tooltip based on screen size or other conditions. For example:
    visibility_class: "hidden md:hidden", show_class: "md:block", hide_class: "md:hidden"
    will show the tooltip on medium screens and hide it on small screens (on hover).
    """

  attr :hide_class, :string,
    default: "hidden",
    doc: """
    Class to hide the tooltip. Use this in conjunction with the visibility_class to
    show/hide the tooltip based on screen size or other conditions. For example:
    visibility_class: "hidden md:hidden", show_class: "md:block", hide_class: "md:hidden"
    will show the tooltip on medium screens and hide it on small screens (on hover).
    """

  attr :placement, :string,
    default: "top",
    values: ~w(top right bottom left top-start right-start bottom-start left-start top-end right-end bottom-end left-end),
    doc: "Placement of the tooltip"

  attr :content, :string, default: nil, doc: "The content for the tooltip"

  attr :show_on_mount, :boolean,
    default: false,
    doc: """
    Whether to show the tooltip on mount. Defaults to false so it's hidden until
    triggered otherwise.
    """

  attr :arrow, :boolean, default: true, doc: "Whether to show the arrow"

  attr :offset_opts, :any,
    default: 6,
    doc: """
    Either a number or a map of options to pass to Floating UI offset middleware
    client-side. For example: `%{\"mainAxis\" => 32}`. Defaults to `6`.
    See [Floating UI Docs](https://floating-ui.com/docs/offset#options).
    """

  attr :flip_opts, :any,
    default: false,
    doc: """
    Either a boolean or a map of options to pass to Floating UI flip middleware
    client-side. Defaults to `true`.
    See [Floating UI Docs](https://floating-ui.com/docs/flip#options).
    """

  attr :shift_opts, :any,
    default: false,
    doc: """
    Either a boolean or a map of options to pass to Floating UI shift middleware
    client-side. For example: `%{\"mainAxis\" => 32}`. Defaults to `nil`.
    See [Floating UI Docs](https://floating-ui.com/docs/shift#options).
    """

  attr :rest, :global, doc: "Additional attributes to be added to the tooltip"

  slot :inner_block, doc: "The slot for the tooltip content"

  def fui_tooltip(assigns) do
    ~H"""
    <div
      phx-hook="FuiTooltip"
      id={@id}
      role="tooltip"
      class={[
        "fui-tooltip text-[--tooltip-text-color] bg-[--tooltip-color]",
        "absolute top-0 left-0 w-fit max-w-xs",
        "whitespace-normal rounded px-2 py-1",
        "text-sm font-medium",
        @visibility_class,
        @class
      ]}
      data-show={@show_class}
      data-hide={@hide_class}
      data-placement={@placement}
      data-show-on-mount={"#{@show_on_mount}"}
      data-offset-opts={maybe_encode_opts(@offset_opts)}
      data-flip-opts={maybe_encode_opts(@flip_opts)}
      data-shift-opts={maybe_encode_opts(@shift_opts)}
      {@rest}
    >
      <%= render_slot(@inner_block) || @content %>
      <div :if={@arrow} id={"#{@id}_fui_arrow"} class="bg-[--tooltip-color] size-2 absolute rotate-45">
      </div>
    </div>
    """
  end

  defp maybe_encode_opts(nil), do: nil
  defp maybe_encode_opts(opts) when is_map(opts), do: Jason.encode!(opts)
  defp maybe_encode_opts(opts), do: opts
end
