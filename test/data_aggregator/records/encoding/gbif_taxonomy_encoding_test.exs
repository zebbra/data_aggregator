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
      invalid_record = record_fixture_for_encoding_gbif_taxonomy_invalid()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the encoded_record", %{
      correct_record: correct_record
    } do
      {:ok, encoded_record} = Record.encode(correct_record, :gbif_taxonomy)

      assert encoded_record !== nil

      lookedup_encoded_record = EncodedRecord.get_by_record!(encoded_record)

      assert lookedup_encoded_record !== nil
      assert lookedup_encoded_record.tax_family === "Muscicapidae"
      assert lookedup_encoded_record.tax_scientific_name === "Oenanthe Vieillot, 1816"
      assert encoded_record.state === :encoded
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the failed_record and the error",
         %{invalid_record: invalid_record} do
      {{:error, error}, logs} =
        with_log(fn -> Record.encode(invalid_record, :gbif_taxonomy) end)

      encoded_record = Record.get_by_id!(invalid_record.id)

      assert encoded_record != nil
      assert error != nil
      assert encoded_record.state == :failed

      assert logs =~
               "For this species name we could not find a matching taxonomy. matchType \\\"HIGHERRANK\\\" is not accepted"
    end
  end
end
