defmodule DataAggregator.SwissSpeciesEncodingTest do
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

      invalid_record = record_fixture_for_encoding_swiss_species()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "encode/2 for :swiss_species catalog which returns the encoded_record", %{
      correct_record: correct_record
    } do
      expect_correct_swiss_species_api_call()

      {:ok, encoded_record} = Record.encode(correct_record, :swiss_species)

      assert encoded_record !== nil

      lookedup_encoded_record = EncodedRecord.get_by_record!(encoded_record)

      assert lookedup_encoded_record !== nil
      assert lookedup_encoded_record.tax_taxon_id_ch === 15_311

      assert lookedup_encoded_record.tax_accepted_name_usage ===
               "Enantiulus dentigerus (Verhoeff, 1901)"

      assert lookedup_encoded_record.tax_scientific_name ===
               "Enantiulus dentigerus (Verhoeff, 1901)"

      assert lookedup_encoded_record.tax_accepted_name_usage_id === nil
      assert lookedup_encoded_record.tax_taxon_rank === "SPECIES"
      assert encoded_record.state === :encoded
    end

    test "encode/2 for :swiss_species catalog which returns the failed_record and the error",
         %{invalid_record: invalid_record} do
      {{:error, error}, logs} =
        with_log(fn -> Record.encode(invalid_record, :swiss_species) end)

      encoded_record = Record.get_by_id!(invalid_record.id)

      assert encoded_record.state === :failed
      assert error != nil
      assert logs =~ "no matching record found for taxon_id: 0"

      assert encoded_record.errors |> Map.get("encoding") |> Map.get("swiss_species") =~
               "no matching record found for taxon_id: 0"
    end
  end
end
