defmodule DataAggregatorWeb.Headless.Hidden do
  @moduledoc """
  Hidden inputs are used to attach data to a form without displaying it.
  """

  use Phoenix.Component

  import Bitwise, only: [&&&: 2, <<<: 2]

  @none 1 <<< 0
  def hidden_features_none, do: @none
  @focusable 1 <<< 1
  def hidden_features_focusable, do: @focusable
  @hidden 1 <<< 2
  def hidden_features_hidden, do: @hidden

  @doc ~S"""
  Renders a hidden input component.
  """

  attr :features, :integer, default: @none
  attr :rest, :global, include: ~w(readonly checked form name value)

  def hidden(assigns) do
    ~H"""
    <input
      class={[
        "border-px w-[1px] fixed top-px left-px -m-px h-0 overflow-hidden whitespace-nowrap p-0",
        hidden?(@features) && "hidden"
      ]}
      aria-hidden={aria_hidden?(@features, @rest[:aria_hidden])}
      {@rest}
    />
    """
  end

  defp hidden?(features) do
    (features &&& @hidden) == @hidden && !((features &&& @focusable) === @focusable)
  end

  defp aria_hidden?(features, aria_hidden) do
    if (features &&& @focusable) === @focusable do
      true
    else
      aria_hidden || nil
    end
  end
end
