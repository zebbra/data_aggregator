defmodule DataAggregatorWeb.Components.Progress do
  @moduledoc """
  Progress bars
  """

  use Phoenix.Component

  attr :value, :integer, default: nil, doc: "adds a value to your progress bar"
  attr :max, :integer, default: 100, doc: "sets a max value for your progress bar"
  attr :class, :string, default: "", doc: "CSS class"
  attr :rest, :global

  def progress(assigns) do
    ~H"""
    <progress class={["progress", @class]} value={@value} max={@max} {@rest} />
    """
  end
end
