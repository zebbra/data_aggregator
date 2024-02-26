defmodule DataAggregator.CoordinatesTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Misc.Coordinates

  describe "coordinates" do
    test "lv95_to_wgs84!/1 returns coordinates in wgs84 format for given lv95 coordinates - correct" do
      input = %Coordinates{
        e: 2_601_390.822,
        n: 1_199_508.775
      }

      expected = %Coordinates{
        e: 7.456905642729698,
        n: 46.946660986374766
      }

      assert Coordinates.lv95_to_wgs84!(input) === expected
    end

    test "wgs84_to_lv95!/1 returns coordinates in lv95 format for given wgs84 coordinates - correct" do
      input = %Coordinates{
        e: 7.456901075,
        n: 46.946662916
      }

      expected = %Coordinates{
        e: 2_601_390.8090730147,
        n: 1_199_508.8017213494
      }

      assert Coordinates.wgs84_to_lv95!(input) === expected
    end
  end

  test "lv95_to_wgs84!/1 returns coordinates in wgs84 format for given lv95 coordinates - incorrect" do
    input = %Coordinates{
      e: 2_601_390.822,
      n: 1_199_508.775
    }

    expected = %Coordinates{
      e: 7.456904242424242,
      n: 46.946664242424242
    }

    assert Coordinates.lv95_to_wgs84!(input) !== expected
  end

  test "wgs84_to_lv95!/1 returns coordinates in lv95 format for given wgs84 coordinates - incorrect" do
    input = %Coordinates{
      e: 7.456901075,
      n: 46.946662916
    }

    expected = %Coordinates{
      e: 2_601_390.4242424242,
      n: 1_199_508.4242424242
    }

    assert Coordinates.wgs84_to_lv95!(input) !== expected
  end

  test "lv95_to_wgs84!/1 returns coordinates in wgs84 format for given lv95 coordinates - error" do
    input = %Coordinates{
      e: nil,
      n: nil
    }

    assert_raise ArithmeticError, fn -> Coordinates.lv95_to_wgs84!(input) end
  end

  test "wgs84_to_lv95!/1 returns coordinates in lv95 format for given wgs84 coordinates - error" do
    input = %Coordinates{
      e: nil,
      n: nil
    }

    assert_raise ArithmeticError, fn -> Coordinates.wgs84_to_lv95!(input) end
  end
end
