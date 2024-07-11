defmodule Pagify.MiscTest do
  @moduledoc false

  use ExUnit.Case

  doctest Pagify.Misc, import: true

  describe "stringify_keys/1" do
    test "converts maps with date values" do
      map = %{
        "and" => [
          %{
            "and" => [
              %{"eve_event_date" => %{"greater_than_or_equal" => ~D[2024-06-11]}},
              %{"eve_event_date" => %{"less_than_or_equal" => ~D[2024-07-11]}}
            ]
          }
        ]
      }

      assert Pagify.Misc.stringify_keys(map) == map
    end
  end
end
