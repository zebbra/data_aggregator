defmodule DataAggregator.GbifTaxonomyEncodingTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mimic
  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  import DataAggregator.EncodingFixtures

  describe "encoding of records with " do
    setup do
      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_invalid_confidence()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the encoded_record", %{
      correct_record: correct_record
    } do
      # mocking the api calls to the GBIF API
      expect_correct_matching_api_call()
      expect_correct_species_api_call()

      {:ok, encoding_result} = Record.encode(correct_record, :gbif_taxonomy)

      %{encoded_record: encoded_record, error: error, failed_record: failed_record} =
        encoding_result

      assert encoded_record !== nil

      lookedup_encoded_record = EncodedRecord.get_by_record!(encoded_record)

      assert lookedup_encoded_record !== nil
      assert failed_record === nil
      assert error === nil
      assert lookedup_encoded_record.tax_family === "Muscicapidae"
      assert lookedup_encoded_record.tax_scientific_name === "Oenanthe Vieillot, 1816"
      assert encoded_record.state === :encoded
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the failed_record and the error",
         %{invalid_record: invalid_record} do
      # mocking the api call to the GBIF API
      expect_invalid_confidence_from_matching_api_call()

      {{:ok, encoding_result}, logs} =
        with_log(fn -> Record.encode(invalid_record, :gbif_taxonomy) end)

      %{encoded_record: encoded_record, error: error, failed_record: failed_record} =
        encoding_result

      assert encoded_record === nil
      assert failed_record !== nil
      assert error !== nil
      assert failed_record.state === :encoding_failed
      assert logs =~ "is not confident (min 80) enough"
    end
  end
end
