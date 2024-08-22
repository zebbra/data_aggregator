defmodule DataAggregator.ForwardGeoEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "forward encoding of records with " do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

      record_fixture = record_fixture_for_forward_geo_encoding_correct()

      [
        record_fixture: record_fixture
      ]
    end

    test "encode/2 for :geo_forward catalog - forward geo encoding - successful",
         %{
           record_fixture: record_fixture
         } do
      {:ok, record} = Record.encode(record_fixture, :geo_forward)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)
      assert encoded_record !== nil

      assert_map_includes(encoded_record, %{
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_state_province: "Bern",
        loc_municipality: "Liebefeld"
      })

      assert record.state === :encoded
    end

    test "encode/2 for :geo_forward catalog - forward geo encoding - (with locality) successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_locality: "Niesen",
          loc_continent: nil,
          loc_country: "Switzerland",
          loc_country_code: nil,
          loc_municipality: nil,
          loc_state_province: nil
        })

      {:ok, record} = Record.encode(record_fixture, :geo_forward)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)
      assert encoded_record !== nil

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: nil,
        loc_decimal_longitude: nil,
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_locality: "Niesen",
        loc_municipality: "Reichenbach im Kandertal",
        loc_state_province: "Bern"
      })

      assert record.state === :encoded
    end

    test "encode/2 for :geo_forward catalog - forward geo encoding - (no changes) successful",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
          loc_locality: "Europe",
          loc_continent: "Europe",
          loc_country: "Switzerland",
          loc_country_code: "ch",
          loc_municipality: "Lausanne",
          loc_state_province: "Vaud"
        })

      {:ok, record} = Record.encode(record_fixture, :geo_forward)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id)
      assert encoded_record !== nil

      assert_map_includes(encoded_record, %{
        loc_decimal_latitude: nil,
        loc_decimal_longitude: nil,
        loc_swiss_coordinates_x: nil,
        loc_swiss_coordinates_y: nil,
        loc_locality: "Europe",
        loc_continent: "Europe",
        loc_country: "Switzerland",
        loc_country_code: "ch",
        loc_municipality: "Lausanne",
        loc_state_province: "Vaud"
      })

      assert record.state === :encoded
    end

    test "encode/2 for :geo_forward catalog - forward geo encoding - error",
         %{
           record_fixture: record_fixture
         } do
      record_fixture =
        update_fixtures!(record_fixture, %{
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

      {{:ok, _record}, logs} =
        with_log(fn -> Record.encode(record_fixture, :geo_forward) end)

      encoded_record =
        record_fixture.id
        |> EncodedRecord.get_by_record!()
        |> Ash.load!([:record])

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

      assert encoded_record.record.state === :failed

      assert logs =~
               "The attributes necessary to forward geo encode were not found on encoded_record"
    end
  end

  defp update_fixtures!(record_fixture, update_set) do
    record_fixture = Record.update!(record_fixture, update_set)
    encoded_record = EncodedRecord.get_by_record!(record_fixture.id)
    EncodedRecord.update!(encoded_record, update_set)
    record_fixture
  end
end
