defmodule Storybook.Collections.CollectionStateBadge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Components

  def function, do: &Components.collection_state_badge/1

  def variations do
    for state <- available_states() do
      %Variation{
        id: state,
        attributes: %{
          state: state
        }
      }
    end
  end

  defp available_states do
    AshStateMachine.Info.state_machine_all_states(DataAggregator.Records.Collection)
  end
end
