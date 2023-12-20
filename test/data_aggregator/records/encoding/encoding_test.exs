defmodule DataAggregator.EncodingTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Record

  import DataAggregator.EncodingFixtures

  describe "encoding of records with " do
    setup do
      records = [
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding()
      ]

      [records: records]
    end

    test "encode/1 for :gbif_taxonomy catalog which returns all successful encoded_records", %{
      records: records
    } do
      expect(Req, :get, fn _, _ ->
        {:ok,
         %{
           status: 200,
           body: correct_response_body()
         }}
      end)

      {:ok, encoding_result} = Record.encode(records)

      # add more asserts for encoded fields on encoded_record items
      assert Enum.count(encoding_result.records) == 5

      assert Enum.each(encoding_result.records, fn encoded_record ->
               assert encoded_record.tax_family === "Muscicapidae"
               assert encoded_record.tax_scientific_name === "Oenanthe Pallas, 1771"
             end)

      assert Enum.empty?(encoding_result.errors)
    end

    test "encode/1 for :gbif_taxonomy catalog which returns successful encoded_records and errors",
         %{
           records: records
         } do
      expect(Req, :get, fn _, _ ->
        {:ok,
         %{
           status: 200,
           body: response_body_with_invalid_confidence()
         }}
      end)

      {{:ok, encoding_result}, logs} = with_log(fn -> Record.encode(records) end)

      # add more asserts for encoded fields on encoded_record items
      assert Enum.count(encoding_result.records) == 4
      assert Enum.empty?(encoding_result.errors) == false

      assert logs =~ "is not confident (min 80) enough"
    end
  end
end
