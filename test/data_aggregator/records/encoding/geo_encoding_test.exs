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
    test "encode/2 for :geo catalog - reverse geo encoding - successful",
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

    # test "encode/2 for :geo catalog which returns ok but no matching record",
    #      %{
    #        correct_record_forward: correct_record_forward,
    #        correct_record_reverse: correct_record_reverse,
    #        invalid_record_forward: invalid_record_forward,
    #        invalid_record_reverse: invalid_record_reverse
    #      } do
    #   {{:ok, record}, logs} =
    #     with_log(fn -> Record.encode(invalid_record, :geo) end)

    #   encoded_record = Record.get_by_id!(invalid_record.id)

    #   assert encoded_record.state === :encoded
    #   assert record != nil
    #   assert logs =~ "no matching record found for taxon_id: 0"
    # end

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
