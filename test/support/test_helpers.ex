defmodule DataAggregator.TestHelpers do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ash.Test,
        only: [
          assert_has_error: 2,
          assert_has_error: 3,
          refute_has_error: 2,
          refute_has_error: 3
        ]

      # Common assertions provided by
      # https://github.com/devonestes/assertions
      import Assertions
      import DataAggregator.TestHelpers

      # Provides `with_log/1` and `assert_log/1`
      # https://hexdocs.pm/ex_unit/ExUnit.CaptureLog.html
      import ExUnit.CaptureLog
    end
  end

  @doc """
  Helper for `Assertions.assert_maps_equal/3` that expects all keys of the
  expected map to be equal to the actual map.
  """
  defmacro assert_map_includes(actual, expected) do
    quote do
      assert_maps_equal(unquote(actual), unquote(expected), Map.keys(unquote(expected)))
    end
  end
end
