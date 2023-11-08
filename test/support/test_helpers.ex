defmodule DataAggregator.TestHelpers do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import DataAggregator.TestHelpers

      import Ash.Test,
        only: [
          assert_has_error: 2,
          assert_has_error: 3,
          refute_has_error: 2,
          refute_has_error: 3
        ]
    end
  end

  def assert_maps(maps, attributes) do
    assert length(maps) == length(attributes)

    for {map, attributes} <- Enum.zip(maps, attributes) do
      assert_map(map, attributes)
    end
  end

  def assert_map(map, attributes) do
    keys = Map.keys(attributes)
    assert fetch_map_keys(map, keys) == attributes
  end

  defp fetch_map_keys(map, keys) do
    for key <- keys, into: %{} do
      {key, Map.fetch!(map, key)}
    end
  end
end
