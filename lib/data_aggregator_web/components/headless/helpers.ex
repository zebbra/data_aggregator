defmodule DataAggregatorWeb.Headless.Helpers do
  def root_id(id) do
    id
    |> String.split("__")
    |> List.first()
  end

  def extract_duration(transition_map)

  def extract_duration({transition_class, _starting, _ending}) do
    extract_duration_from_transition(transition_class)
  end

  def extract_duration(_) do
    nil
  end

  defp extract_duration_from_transition(transition) do
    segments = String.split(transition)

    Enum.find_value(segments, fn segment ->
      case String.split(segment, "-") do
        ["duration" <> _, duration | _] ->
          duration

        _ ->
          nil
      end
    end)
  end
end
