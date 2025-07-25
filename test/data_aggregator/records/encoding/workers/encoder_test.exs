defmodule DataAggregator.Records.Import.Workers.EncoderTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder

  describe "DataAggregator.Records.Record.Workers.Encoder.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_gbif_taxonomy_invalid()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "succeeds a valid record to encode", %{
      correct_record: correct_record
    } do
      expect_correct_swiss_species_api_call()

      {:ok, record} =
        perform_job(Encoder, %{id: correct_record.id, collection_id: correct_record.collection_id})

      assert record.state == :encoded

      encoded_record =
        EncodedRecord.get_by_record!(record.id, tenant: correct_record.collection_id)

      assert_map_includes(encoded_record, %{
        tax_class: "Aves",
        tax_family: "Muscicapidae",
        tax_genus: "Oenanthe",
        tax_kingdom: "Animalia",
        tax_order: "Passeriformes",
        tax_phylum: "Chordata",
        tax_scientific_name: "Enantiulus dentigerus (Verhoeff, 1901)",
        tax_taxon_id: 2_435_194,
        tax_accepted_name_usage: "Enantiulus dentigerus (Verhoeff, 1901)",
        tax_taxon_id_ch: 15_311,
        tax_taxon_rank: "SPECIES",
        loc_country: "Switzerland",
        loc_municipality: nil,
        loc_state_province: "Bern",
        loc_continent: "Europe",
        loc_country_code: "CH",
        iucn_redlist_category: "EX"
      })
    end

    @tag capture_log: true
    test "succeeds a partial valid record and performs all encodings but sets state to failed", %{
      correct_record: correct_record
    } do
      correct_record = update_record_fixtures!(correct_record, %{loc_country: nil})
      expect_correct_swiss_species_api_call()

      {:ok, record} =
        perform_job(Encoder, %{id: correct_record.id, collection_id: correct_record.collection_id})

      assert record.state == :failed

      encoded_record =
        EncodedRecord.get_by_record!(record.id, tenant: correct_record.collection_id)

      assert_map_includes(encoded_record, %{
        tax_class: "Aves",
        tax_family: "Muscicapidae",
        tax_genus: "Oenanthe",
        tax_kingdom: "Animalia",
        tax_order: "Passeriformes",
        tax_phylum: "Chordata",
        tax_scientific_name: "Enantiulus dentigerus (Verhoeff, 1901)",
        tax_taxon_id: 2_435_194,
        tax_accepted_name_usage: "Enantiulus dentigerus (Verhoeff, 1901)",
        tax_taxon_id_ch: 15_311,
        tax_taxon_rank: "SPECIES",
        loc_country: nil,
        loc_municipality: nil,
        loc_state_province: "Bern",
        loc_continent: nil,
        loc_country_code: nil,
        iucn_redlist_category: "EX"
      })
    end

    # at the moment there is no failing matchType, we accept all results
    @tag :pending
    test "fails an invalid record to encode", %{invalid_record: invalid_record} do
      {_result, logs} = with_log(fn -> perform_job(Encoder, %{id: invalid_record.id}) end)

      record = Record.get_by_id!(invalid_record.id)

      assert record.state == :failed

      assert logs =~
               "For this species name we could not find a matching taxonomy. matchType \\\"HIGHERRANK\\\" is not accepted"
    end
  end
end
