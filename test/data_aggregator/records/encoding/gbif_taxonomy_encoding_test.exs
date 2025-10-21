defmodule DataAggregator.GbifTaxonomyEncodingTest do
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

      correct_record_no_synonym =
        record_fixture_for_encoding(%{tax_scientific_name: "Oenanthe Pallas no synonym"})

      invalid_record = record_fixture_for_encoding_gbif_taxonomy_invalid()

      [
        correct_record: correct_record,
        correct_record_no_synonym: correct_record_no_synonym,
        invalid_record: invalid_record
      ]
    end

    test "encode/2 for :gbif_taxonomy catalog which returns the encoded_record", %{
      correct_record: correct_record
    } do
      {:ok, encoded_record} =
        Record.encode(correct_record, :gbif_taxonomy, tenant: correct_record.collection_id)

      assert encoded_record !== nil

      lookedup_encoded_record =
        EncodedRecord.get_by_record!(encoded_record.id, tenant: correct_record.collection_id)

      assert lookedup_encoded_record !== nil

      assert_map_includes(lookedup_encoded_record, %{
        tax_scientific_name: "Oenanthe Vieillot, 1816",
        tax_genus: "Oenanthe",
        tax_family: "Muscicapidae",
        tax_order: "Passeriformes",
        tax_class: "Aves",
        tax_phylum: "Chordata",
        tax_kingdom: "Animalia"
      })

      assert encoded_record.state === :encoded
    end

    test "encode/2 for :gbif_taxonomy catalog, finds no synonym in the response and returns the encoded_record",
         %{
           correct_record_no_synonym: correct_record_no_synonym
         } do
      {:ok, encoded_record} =
        Record.encode(correct_record_no_synonym, :gbif_taxonomy, tenant: correct_record_no_synonym.collection_id)

      assert encoded_record !== nil

      lookedup_encoded_record =
        EncodedRecord.get_by_record!(encoded_record.id,
          tenant: correct_record_no_synonym.collection_id
        )

      assert lookedup_encoded_record !== nil

      assert_map_includes(lookedup_encoded_record, %{
        tax_class: "Magnoliopsida",
        tax_family: "Asteraceae",
        tax_genus: "Bellis",
        tax_kingdom: "Plantae",
        tax_order: "Asterales",
        tax_phylum: "Tracheophyta",
        tax_scientific_name: "Bellis perennis L."
      })

      assert encoded_record.state === :encoded
    end

    # at the moment there is no failing matchType, we accept all results
    @tag :pending
    test "encode/2 for :gbif_taxonomy catalog which returns the failed_record and the error",
         %{invalid_record: invalid_record} do
      {{:error, error}, logs} =
        with_log(fn ->
          Record.encode(invalid_record, :gbif_taxonomy, tenant: invalid_record.collection_id)
        end)

      encoded_record = Record.get_by_id!(invalid_record.id)

      assert encoded_record
      assert error
      assert encoded_record.state == :failed

      assert logs =~
               "For this species name we could not find a matching taxonomy. matchType \\\"HIGHERRANK\\\" is not accepted"
    end
  end
end
