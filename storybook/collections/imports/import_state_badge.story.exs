defmodule Storybook.Collections.Imports.ImportStateBadge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Import.Components

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
    AshStateMachine.Info.state_machine_all_states(DataAggregator.Records.Import)
  end
end
