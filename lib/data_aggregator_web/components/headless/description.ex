defmodule DataAggregatorWeb.Headless.Description do
  @moduledoc """
  Descriptions are used to attach a description to an input element.
  """

  use Phoenix.Component

  @doc ~S"""
  Renders a description component. Mounts the DescriptionHook.
  """

  attr :id, :string, required: true
  attr :as, :string, default: "p"
  attr :rest, :global
  slot :inner_block, required: true

  def description(assigns) do
    ~H"""
    <.dynamic_tag phx-hook="Description" id={@id} name={@as} {@rest}>
      <%= render_slot(@inner_block) %>
    </.dynamic_tag>
    """
  end
end
