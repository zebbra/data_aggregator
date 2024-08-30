defmodule DataAggregator.SwissSpeciesEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "encoding of records with " do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      correct_record = record_fixture_for_encoding()

      invalid_record = record_fixture_for_encoding_swiss_species_invalid()

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

      lookedup_encoded_record = EncodedRecord.get_by_record!(encoded_record.id)

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

    test "encode/2 for :swiss_species catalog which returns ok but no matching record",
         %{invalid_record: invalid_record} do
      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(invalid_record, :swiss_species) end)

      encoded_record = Record.get_by_id!(invalid_record.id)

      assert encoded_record.state === :encoded
      assert record != nil
      assert logs =~ "no matching encoded_record found for taxon_id: 0"
    end

    test "encode/2 for :swiss_species catalog which returns an error", %{
      invalid_record: invalid_record
    } do
      expect_failing_swiss_species_api_call()

      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(invalid_record, :swiss_species) end)

      record = Record.get_by_id!(record.id, load: [:encoded])

      assert record.encoded == false
      assert logs =~ "Error while encoding the encoded_record"
      assert logs =~ "with the swiss species catalog: %Ash.Error.Unknown{}"
      assert logs =~ "unknown error occured"
    end

    test "encode/2 for :unknown catalog which returns an error", %{
      correct_record: correct_record
    } do
      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(correct_record, :unknown) end)

      record = Record.get_by_id!(record.id, load: [:encoded])
      assert record.encoded == false

      assert logs =~ "no encoding strategy found for catalog: :unknown"
    end

    @tag capture_log: true
    test "encode/2 for :swiss_species catalog fails if taxon_id is not provided", %{
      correct_record: record
    } do
      record = update_record_fixtures!(record, %{tax_taxon_id: nil})
      Record.encode(record, :swiss_species)

      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(record, :swiss_species) end)

      assert record.state === :failed

      assert logs =~ "taxon_id is empty"
    end
  end
end
