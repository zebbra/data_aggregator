defmodule Storybook.Components.Flash do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Button
  alias DataAggregatorWeb.Components.Flash
  alias DataAggregatorWeb.Components.Transitions

  def function, do: &Flash.flash/1
  def imports, do: [{Transitions, [show: 1]}, {Button, [button: 1]}]

  def template(assigns) do
    """
    <div class="p-6 rounded bg-base-100" data-theme={@theme}>
      <.button phx-click={show("#:variation_id")} lsb-code-hidden label="Open flash" />
      <.lsb-variation/>
    </div>
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
