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
        "hidden fixed inset-0",
        @variant == "slideover" && "bg-gray-500/75 dark:bg-[#0f172ae6]",
        @variant == "modal" && "bg-gray-500/75 dark:bg-[#0f172ae6]"
      ]}
      aria-hidden="true"
    />
    """
  end
end
