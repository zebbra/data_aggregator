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

      {:ok, encoded_record} =
        Record.encode(correct_record, :swiss_species, tenant: correct_record.collection_id)

      assert encoded_record !== nil

      lookedup_encoded_record =
        EncodedRecord.get_by_record!(encoded_record.id, tenant: correct_record.collection_id)

      assert lookedup_encoded_record !== nil
      assert lookedup_encoded_record.tax_taxon_id_ch === 15_311

      assert lookedup_encoded_record.tax_accepted_name_usage ===
               "Enantiulus dentigerus (Verhoeff, 1901)"

      assert lookedup_encoded_record.tax_scientific_name ===
               "Enantiulus dentigerus (Verhoeff, 1901)"

      assert lookedup_encoded_record.tax_accepted_name_usage_id === "1669856"
      assert lookedup_encoded_record.tax_taxon_rank === "SPECIES"
      assert lookedup_encoded_record.oth_swiss_species_center === "infofauna"
      assert lookedup_encoded_record.oth_swiss_species_registered == true
      assert lookedup_encoded_record.oth_swiss_species_registered_at
      assert encoded_record.state === :encoded
    end

    test "encode/2 for :swiss_species catalog which returns ok but no matching record",
         %{invalid_record: invalid_record} do
      {{:ok, record}, logs} =
        with_log(fn ->
          Record.encode(invalid_record, :swiss_species, tenant: invalid_record.collection_id)
        end)

      lookedup_record = Record.get_by_id!(record.id, tenant: record.collection_id)

      lookedup_encoded_record =
        EncodedRecord.get_by_record!(record.id, tenant: record.collection_id)

      assert lookedup_encoded_record.oth_swiss_species_center === nil
      assert lookedup_encoded_record.oth_swiss_species_registered == false
      assert lookedup_encoded_record.oth_swiss_species_registered_at
      assert lookedup_record.state === :encoded
      assert lookedup_record
      assert logs =~ "no matching encoded_record found for taxon_id: 0"
    end

    test "encode/2 for :swiss_species catalog which returns an error", %{
      invalid_record: invalid_record
    } do
      expect_failing_swiss_species_api_call()

      {{:ok, record}, logs} =
        with_log(fn ->
          Record.encode(invalid_record, :swiss_species, tenant: invalid_record.collection_id)
        end)

      record =
        Record.get_by_id!(record.id, load: [:encoded], tenant: invalid_record.collection_id)

      assert record.encoded == false
      assert logs =~ "Error while encoding the encoded_record"
      assert logs =~ "with the swiss species catalog: %Ash.Error.Unknown{}"
      assert logs =~ "unknown error occured"
    end

    test "encode/2 for :unknown catalog which returns an error", %{
      correct_record: correct_record
    } do
      {{:ok, record}, logs} =
        with_log(fn ->
          Record.encode(correct_record, :unknown, tenant: correct_record.collection_id)
        end)

      record =
        Record.get_by_id!(record.id, load: [:encoded], tenant: correct_record.collection_id)

      assert record.encoded == false

      assert logs =~ "no encoding strategy found for catalog: :unknown"
    end

    @tag capture_log: true
    test "encode/2 for :swiss_species catalog fails if taxon_id is not provided", %{
      correct_record: record
    } do
      record = update_record_fixtures!(record, %{tax_taxon_id: nil})
      Record.encode(record, :swiss_species, tenant: record.collection_id)

      {{:ok, record}, logs} =
        with_log(fn -> Record.encode(record, :swiss_species, tenant: record.collection_id) end)

      assert record.state === :failed

      assert logs =~ "taxon_id is empty"
    end
  end
end
