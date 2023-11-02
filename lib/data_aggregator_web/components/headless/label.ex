defmodule DataAggregatorWeb.Headless.Label do
  @moduledoc """
  Labels are used to attach a label to an input element.
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a label component. Mounts the LabelHook.
  """

  attr :id, :string, required: true
  attr :as, :string, default: "label"
  attr :passive, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <.dynamic_tag phx-hook="Label" id={@id} name={@as} data-passive={@passive} {@rest}>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end
end
