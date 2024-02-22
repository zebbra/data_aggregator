defmodule Storybook.Collections.StateIndicator do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Encoding.Components

  def function, do: &Components.encoding_state_badge/1

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
      },
      %VariationGroup{
        id: :with_reason,
        variations:
          for state <- available_states() do
            %Variation{
              id: state,
              attributes: %{
                state: state,
                reason: "Some reason"
              }
            }
          end
      },
      %VariationGroup{
        id: :small,
        variations:
          for state <- available_states() do
            %Variation{
              id: state,
              attributes: %{
                state: state,
                small: true
              }
            }
          end
      },
      %VariationGroup{
        id: :small_with_reason,
        variations:
          for state <- available_states() do
            %Variation{
              id: state,
              attributes: %{
                state: state,
                small: true,
                reason: "Some reason"
              }
            }
          end
      }
    ]
  end

  defp available_states do
    ~w(encoded success failed error encoding queued unchanged incomplete imported unknown)a
  end
end
