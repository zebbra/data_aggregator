defmodule DataAggregatorWeb.Components.Button do
  @moduledoc """
  Button components.
  """

  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders a table action button.

  """
  attr :disabled, :boolean, default: false, doc: "whether the button is disabled"
  attr :icon, :string, doc: "the icon name"
  attr :icon_class, :string, default: nil, doc: "additional icon classes"

  attr :rest, :global,
    include: ~w(phx-click phx-value-id patch data-tip data-confirm data-confirm_id),
    doc: "the arbitrary HTML attributes to add to the button"

  def table_action_button(assigns) do
    ~H"""
    <.link
      type="button"
      class={[
        "link tooltip link-hover btn btn-sm btn-circle btn-ghost inline-flex",
        @disabled && "text-base-content/20 pointer-events-none"
      ]}
      {@rest}
    >
      <.icon
        name={@icon}
        class={
          class_names([
            "size-5",
            if(@disabled,
              do: "text-base-content/20",
              else: "text-base-content/75"
            ),
            @icon_class
          ])
        }
      />
    </.link>
    """
  end

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
    <.dynamic_tag tag_name={@as} class={["absolute flex", position_class(@position, @dense)]} {@rest}>
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
