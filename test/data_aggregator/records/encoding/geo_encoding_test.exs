defmodule DataAggregator.GeoEncodingTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic
  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  import DataAggregator.EncodingFixtures

  describe "encoding of records with " do
    setup do
      invalid_record_forward = record_fixture_for_forward_geo_encoding_invalid()
      invalid_record_reverse = record_fixture_for_reverse_geo_encoding_invalid()

      correct_record_forward = record_fixture_for_forward_geo_encoding_correct()
      correct_record_reverse = record_fixture_for_reverse_geo_encoding_correct()

      [
        correct_record_forward: correct_record_forward,
        correct_record_reverse: correct_record_reverse,
        invalid_record_forward: invalid_record_forward,
        invalid_record_reverse: invalid_record_reverse
      ]
    end

    @tag run: true
    test "encode/2 for :geo catalog - reverse geo encoding with intl coordinates - successful",
         %{
           correct_record_reverse: correct_record_reverse
         } do
      {:ok, record} = Record.encode(correct_record_reverse, :geo)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 46.946660986374766,
        loc_decimal_longitude: 7.456905642729698,
        loc_swiss_coordinates_x: 2_601_391.156872048,
        loc_swiss_coordinates_y: 1_199_508.5872802814,
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_state_province: "Bern",
        loc_city: "Bern",
        loc_municipality: "Bern"
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    @tag run: true
    test "encode/2 for :geo catalog - reverse geo encoding with swiss coordinates - successful",
         %{
           correct_record_reverse: correct_record_reverse
         } do
      correct_record_reverse =
        Record.update!(correct_record_reverse, %{
          loc_decimal_latitude: nil,
          loc_decimal_longitude: nil,
          loc_swiss_coordinates_x: 2_601_391.156872048,
          loc_swiss_coordinates_y: 1_199_508.5872802814
        })

      {:ok, record} = Record.encode(correct_record_reverse, :geo)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 46.946659297095934,
        loc_decimal_longitude: 7.456910040693462,
        loc_swiss_coordinates_x: 2_601_391.156872048,
        loc_swiss_coordinates_y: 1_199_508.5872802814,
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_state_province: "Bern",
        loc_city: "Bern",
        loc_municipality: "Bern"
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    @tag run: true
    test "encode/2 for :geo catalog - reverse geo encoding with no coordinates - (no changes 1) successful",
         %{
           correct_record_reverse: correct_record_reverse
         } do
      correct_record_reverse =
        Record.update!(correct_record_reverse, %{
          loc_decimal_latitude: nil,
          loc_decimal_longitude: nil,
          loc_swiss_coordinates_x: nil,
          loc_swiss_coordinates_y: nil
        })

      {:ok, record} = Record.encode(correct_record_reverse, :geo)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: nil,
        loc_decimal_longitude: nil,
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_continent: nil,
        loc_country: nil,
        loc_country_code: nil,
        loc_state_province: nil,
        loc_city: nil,
        loc_municipality: nil
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    @tag run: true
    test "encode/2 for :geo catalog - reverse geo encoding with no coordinates - (no changes 2) successful",
         %{
           correct_record_reverse: correct_record_reverse
         } do
      correct_record_reverse =
        Record.update!(correct_record_reverse, %{
          loc_decimal_latitude: 46.946659297095934,
          loc_decimal_longitude: nil,
          loc_swiss_coordinates_x: 2_601_391.156872048,
          loc_swiss_coordinates_y: nil
        })

      {:ok, record} = Record.encode(correct_record_reverse, :geo)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 46.946659297095934,
        loc_decimal_longitude: nil,
        loc_swiss_coordinates_x: 2_601_391.156872048,
        loc_swiss_coordinates_y: nil,
        loc_continent: nil,
        loc_country: nil,
        loc_country_code: nil,
        loc_state_province: nil,
        loc_city: nil,
        loc_municipality: nil
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    @tag run: true
    test "encode/2 for :geo catalog - reverse geo encoding with wrong coordinates - error (no result)",
         %{
           correct_record_reverse: correct_record_reverse
         } do
      correct_record_reverse =
        Record.update!(correct_record_reverse, %{
          loc_decimal_latitude: 4242.4242,
          loc_decimal_longitude: 2424.2424,
          loc_swiss_coordinates_x: nil,
          loc_swiss_coordinates_y: nil
        })

      {{:error, error}, logs} =
        with_log(fn -> Record.encode(correct_record_reverse, :geo) end)

      encoded_record = Record.get_by_id!(correct_record_reverse.id)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 4242.4242,
        loc_decimal_longitude: 2424.2424,
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_continent: nil,
        loc_country: nil,
        loc_country_code: nil,
        loc_state_province: nil,
        loc_city: nil,
        loc_municipality: nil
      })

      assert encoded_record.state === :failed
      assert error == "No valid response (status 400) from geo api"
      assert logs =~ "No valid response (status 400) from geo api"
    end

    # test "encode/2 for :geo catalog which returns an error", %{
    #   correct_record_forward: correct_record_forward,
    #   correct_record_reverse: correct_record_reverse,
    #   invalid_record_forward: invalid_record_forward,
    #   invalid_record_reverse: invalid_record_reverse
    # } do
    #   # expect_failing_geo_api_call()

    #   {{:error, error}, logs} =
    #     with_log(fn -> Record.encode(invalid_record, :geo) end)

    #   assert %Ash.Error.Unknown{} = error

    #   assert logs =~ "unknown error occured"
    # end

    # test "encode/2 for :unknown catalog which returns an error", %{
    #   correct_record_forward: correct_record_forward,
    #   correct_record_reverse: correct_record_reverse,
    #   invalid_record_forward: invalid_record_forward,
    #   invalid_record_reverse: invalid_record_reverse
    # } do
    #   {{:error, error}, logs} =
    #     with_log(fn -> Record.encode(correct_record, :unknown) end)

    #   assert error === "no encoding strategy found for catalog: :unknown"
    #   assert logs =~ "no encoding strategy found for catalog: :unknown"
    # end
  end
end
