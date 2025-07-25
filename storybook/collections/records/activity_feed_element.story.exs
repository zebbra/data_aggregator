defmodule Storybook.Collections.Records.ActivityFeedElement do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregator.Records.Activity
  alias DataAggregatorWeb.CollectionLive.Record.ActivityFeed

  def function, do: &ActivityFeed.activity_feed_element/1

  def template do
    """
    <div class="h-4" />
    <.psb-variation/>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :default,
        variations:
          for activity <- available_activities() do
            %Variation{
              id: String.to_atom(activity.source),
              attributes: %{
                activity: activity
              }
            }
          end
      }
    ]
  end

  defp available_activities do
    activity_names =
      ~w(import update set_encoded set_encoding_failed update_publication_status update_validation_status other)a

    Enum.reduce(activity_names, [], fn name, acc ->
      activity = %Activity{
        name: name,
        actor: "John Doe",
        date_time: DateTime.utc_now(),
        content: %{},
        source: Atom.to_string(name),
        index: name
      }

      activity = maybe_put_content(activity, name)

      case name do
        :update_publication_status -> iterate_state_machine(acc, name)
        :update_validation_status -> iterate_state_machine(acc, name)
        _ -> [activity | acc]
      end
    end)
  end

  defp iterate_state_machine(activities, :update_publication_status) do
    states = ~w(not_published publishing in_publication published publication_failed stale other)

    Enum.reduce(states, activities, fn state, acc ->
      activity = %Activity{
        name: :update_publication_status,
        actor: "John Doe",
        date_time: DateTime.utc_now(),
        content: %{"publication_status" => state},
        source: "publication_status_#{state}",
        index: "publication_status_#{state}"
      }

      [activity | acc]
    end)
  end

  defp iterate_state_machine(activities, :update_validation_status) do
    states = ~w(not_validated validating in_validation validated validation_failed stale other)

    Enum.reduce(states, activities, fn state, acc ->
      activity = %Activity{
        name: :update_validation_status,
        actor: "John Doe",
        date_time: DateTime.utc_now(),
        content: %{"validation_status" => state},
        source: "validation_status_#{state}",
        index: "validation_status_#{state}"
      }

      [activity | acc]
    end)
  end

  defp maybe_put_content(activity, name) do
    case name do
      :import ->
        activity
        |> Map.put(:content, %{tax_taxon_id: nil})
        |> Map.put(:source, "Import")

      :update ->
        activity
        |> Map.put(:content, %{tax_taxon_id: "1231231"})
        |> Map.put(:source, "GBIF Taxonomy")

      _ ->
        activity
    end
  end
end
