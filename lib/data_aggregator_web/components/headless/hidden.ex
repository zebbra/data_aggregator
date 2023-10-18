defmodule DataAggregatorWeb.Headless.Hidden do
  use Phoenix.Component
  import Bitwise, only: [&&&: 2, <<<: 2]

  @none 1 <<< 0
  def hidden_features_none, do: @none
  @focusable 1 <<< 1
  def hidden_features_focusable, do: @focusable
  @hidden 1 <<< 2
  def hidden_features_hidden, do: @hidden

  attr :features, :integer, default: @none
  attr :rest, :global, include: ~w(readonly checked form name value)

  def hidden(assigns) do
    ~H"""
    <input
      class={[
        "top-px left-px -m-px whitespace-nowrap border-px fixed w-[1px] h-0 p-0 overflow-hidden",
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
