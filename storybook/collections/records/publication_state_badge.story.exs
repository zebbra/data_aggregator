defmodule Storybook.Collections.Records.PublicationStateBadge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Record.Components

  def function, do: &Components.publication_state_badge/1

  def variations do
    [
      %VariationGroup{
        id: :default,
        variations:
          for state <- available_states() do
            %Variation{
              id: state,
              attributes: %{
                state: state
              }
            }
          end
      }
    ]
  end

  defp available_states do
    ~w(not_published publishing in_publication published publication_failed stale)a
  end
end
