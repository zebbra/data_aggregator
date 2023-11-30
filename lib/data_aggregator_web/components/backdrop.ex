defmodule DataAggregatorWeb.Components.Backdrop do
  @moduledoc """
  Backdrop component for modals and slideover components.
  Mostly used internally.
  """

  use Phoenix.Component

  attr :id, :string, required: true
  attr :variant, :string, default: "modal"

  def backdrop(assigns) do
    ~H"""
    <div
      id={@id <> "__backdrop"}
      class={[
        "fixed inset-0 hidden",
        @variant == "slideover" && "bg-neutral/75",
        @variant == "modal" && "bg-neutral/75"
      ]}
      aria-hidden="true"
    />
    """
  end
end
