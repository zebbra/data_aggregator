defmodule Storybook.Collections.ImageUploads.ImageUploadStateBadge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.ImageUpload.Components

  def function, do: &Components.image_upload_state_badge/1

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
    AshStateMachine.Info.state_machine_all_states(DataAggregator.Records.ImageUpload)
  end
end
