defmodule DataAggregatorWeb.Components.CloseButton do
  @moduledoc """
  Close button component.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a close button.

  ## Examples

  ```heex
  <.close_button />
  <.close_button squared />
  <.close_button as="form" method="dialog" />
  <.close_button position="left" on_cancel={JS.push("clicked")} />
  ```
  """
  attr :as, :string, default: "div", doc: "the tag of the close button wrapper"
  attr :squared, :boolean, default: false, doc: "whether the close button is squared or rounded"

  attr :position, :string,
    values: ~w[left right],
    default: "right",
    doc: "the position of the close button"

  attr :dense, :boolean,
    default: false,
    doc: "if true, positions the close button closer to the borders"

  attr :class, :string, default: nil, doc: "Additional CSS classes for the close button"
  attr :icon_class, :string, default: "text-base-content/75", doc: "the icon class"

  attr :rest, :global,
    include: ~w(method),
    doc: "the arbitrary HTML attributes to add to the close button"

  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the close button is clicked"

  def close_button(assigns) do
    ~H"""
    <.dynamic_tag
      name={@as}
      class={[
        "absolute flex",
        position_class(@position, @dense)
      ]}
      {@rest}
    >
      <button
        class={["btn btn-sm btn-ghost", if(@squared, do: "btn-square", else: "btn-circle"), @class]}
        aria-label={~t"close"m}
        phx-click={@on_cancel}
      >
        <.icon name="hero-x-mark-mini" class={@icon_class} />
      </button>
    </.dynamic_tag>
    """
  end

  defp position_class(position, dense)
  defp position_class("left", false), do: "left-4 top-2 sm:top-4"
  defp position_class("right", false), do: "right-4 top-2 sm:top-4"
  defp position_class("left", true), do: "left-2 top-2"
  defp position_class("right", true), do: "right-2 top-2"
end
