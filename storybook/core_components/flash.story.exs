defmodule Storybook.CoreComponents.Flash do
  use PhoenixStorybook.Story, :component
  alias Elixir.DataAggregatorWeb.CoreComponents

  def function, do: &CoreComponents.flash/1
  def imports, do: [{CoreComponents, [button: 1, show: 1]}]

  def template do
    """
    <.button phx-click={show("#:variation_id")} lsb-code-hidden>
      Open flash
    </.button>
    <.lsb-variation/>
    """
  end

  def variations do
    [
      %Variation{
        id: :info_no_title,
        attributes: %{
          kind: :info
        },
        slots: ["Info message"]
      },
      %Variation{
        id: :error_with_title,
        attributes: %{
          kind: :error,
          title: "Flash title"
        },
        slots: ["Error message"]
      }
    ]
  end
end
