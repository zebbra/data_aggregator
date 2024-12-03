defmodule DataAggregatorWeb.Components.Badge do
  @moduledoc """
  This module contains components for the badge.
  """

  use Phoenix.Component

  @doc """
  Renders a badge with different colors.

  ## Examples

  ```heex
  <.badge color="blue">
    Blue badge
  </.badge>
  ```
  """
  attr :class, :string, default: nil, doc: "the badge class"

  attr :color, :string,
    default: "gray",
    values: ~w(gray blue green red orange),
    doc: "the badge color"

  attr :rest, :global, include: ~w(data-tip)

  slot :inner_block, required: true, doc: "the inner block of the badge"

  def badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex h-8 items-center space-x-1.5 whitespace-nowrap rounded-full px-1.5 py-1 text-sm font-medium ring-1 ring-inset",
        badge_color_class(@color),
        cursor_style(@rest),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp badge_color_class("blue"), do: "bg-info/10 text-info ring-info/20 tooltip-info"

  defp badge_color_class("green"), do: "bg-success/10 text-success ring-success/20 tooltip-success"

  defp badge_color_class("red"), do: "bg-error/10 text-error ring-error/20 tooltip-error"

  defp badge_color_class("orange"), do: "bg-warning/10 text-warning ring-warning/20 tooltip-warning"

  defp badge_color_class(_), do: "bg-base-300 text-base-content/60 ring-base-content/30"

  defp cursor_style(%{:"data-tip" => data_tip}) when data_tip != nil do
    "cursor-help"
  end

  defp cursor_style(_), do: nil
end
