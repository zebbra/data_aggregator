defmodule DataAggregator.ReverseGeoEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "reward encoding of records with " do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

      record_fixture = record_fixture_for_reverse_geo_encoding_correct()

      [
        record_fixture: record_fixture
      ]
    end

    test "encode/2 for :geo_reverse catalog - reverse geo encoding with intl coordinates within switzerland - successful",
         %{
           record_fixture: record_fixture
         } do
      {:ok, record} = Record.encode(record_fixture, :geo_reverse)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 46.946660986374766,
        loc_decimal_longitude: 7.456905642729698,
        loc_swiss_coordinates_x: 2_601_391.156872048,
        loc_swiss_coordinates_y: 1_199_508.5872802814,
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_state_province: "Bern",
        loc_municipality: "Bern"
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    test "encode/2 for :geo_reverse catalog - reverse geo encoding with intl coordinates out of switzerland - successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_decimal_latitude: 32.117833,
          loc_decimal_longitude: 20.082039,
          loc_swiss_coordinates_x: nil,
          loc_swiss_coordinates_y: nil
        })

      {:ok, record} = Record.encode(record_fixture, :geo_reverse)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)

      assert_map_includes(encoded_record, %{
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_continent: "Africa",
        loc_country: "Libya",
        loc_country_code: "ly",
        loc_decimal_latitude: 32.117833,
        loc_decimal_longitude: 20.082039,
        loc_municipality: "Benghazi",
        loc_state_province: nil
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    test "encode/2 for :geo_reverse catalog - reverse geo encoding with swiss coordinates - successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_decimal_latitude: nil,
          loc_decimal_longitude: nil,
          loc_swiss_coordinates_x: 2_601_391.156872048,
          loc_swiss_coordinates_y: 1_199_508.5872802814
        })

      {:ok, record} = Record.encode(record_fixture, :geo_reverse)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 46.946659297095934,
        loc_decimal_longitude: 7.456910040693462,
        loc_swiss_coordinates_x: 2_601_391.156872048,
        loc_swiss_coordinates_y: 1_199_508.5872802814,
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_state_province: "Bern",
        loc_municipality: "Bern"
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    test "encode/2 for :geo_reverse catalog - reverse geo encoding with no coordinates - (no changes 1) successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_decimal_latitude: nil,
          loc_decimal_longitude: nil,
          loc_swiss_coordinates_x: nil,
          loc_swiss_coordinates_y: nil
        })

      {:ok, record} = Record.encode(record_fixture, :geo_reverse)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: nil,
        loc_decimal_longitude: nil,
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_continent: nil,
        loc_country: nil,
        loc_country_code: nil,
        loc_state_province: nil,
        loc_municipality: nil
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    test "encode/2 for :geo_reverse catalog - reverse geo encoding with no coordinates - (no changes 2) successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_decimal_latitude: 46.946659297095934,
          loc_decimal_longitude: nil,
          loc_swiss_coordinates_x: 2_601_391.156872048,
          loc_swiss_coordinates_y: nil
        })

      {:ok, record} = Record.encode(record_fixture, :geo_reverse)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 46.946659297095934,
        loc_decimal_longitude: nil,
        loc_swiss_coordinates_x: 2_601_391.156872048,
        loc_swiss_coordinates_y: nil,
        loc_continent: nil,
        loc_country: nil,
        loc_country_code: nil,
        loc_state_province: nil,
        loc_municipality: nil
      })

      assert encoded_record !== nil
      assert record.state === :encoded
    end

    test "encode/2 for :geo_reverse catalog - reverse geo encoding with wrong coordinates - error (no result)",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_decimal_latitude: 4242.4242,
          loc_decimal_longitude: 2424.2424,
          loc_swiss_coordinates_x: nil,
          loc_swiss_coordinates_y: nil
        })

      {{:ok, _record}, logs} =
        with_log(fn -> Record.encode(record_fixture, :geo_reverse) end)

      encoded_record = Record.get_by_id!(record_fixture.id)

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: 4242.4242,
        loc_decimal_longitude: 2424.2424,
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_continent: nil,
        loc_country: nil,
        loc_country_code: nil,
        loc_state_province: nil,
        loc_municipality: nil
      })

      assert encoded_record.state === :failed

      assert logs =~ "No valid response (status 400) from geo api"
    end
  end

  defp update_fixtures!(record_fixture, update_set) do
    record_fixture = Record.update!(record_fixture, update_set)
    encoded_record = EncodedRecord.get_by_record!(record_fixture.id)
    EncodedRecord.update!(encoded_record, update_set)
    record_fixture
  end
end
