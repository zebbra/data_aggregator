defmodule Storybook.Imports.ImportStateBadge do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.ImportLive.Components

  def function, do: &Components.import_state_badge/1

  def variations do
    for state <- available_states() do
      %Variation{
        id: state,
        attributes: %{
          state: state,
          progress: 0.75
        }
      }
    end
  end

  defp available_states do
    DataAggregator.Records.Import
    |> AshStateMachine.Info.state_machine_all_states()
  end
end
