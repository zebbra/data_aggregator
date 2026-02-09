defmodule DataAggregator.GbifTaxonomyEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.CatalogOfLife, as: CoL
  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "encoding of records with " do
    setup do
      stub_with(CoL.RestAPI, CoL.RestAPIStub)
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      correct_record =
        record_fixture_for_encoding(%{tax_scientific_name: "Anergates atratulus (Schenck, 1852)"})

      invalid_record =
        record_fixture_for_encoding(%{tax_scientific_name: "Invalid Species Name"})

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "encode/2 for :col_taxonomy catalog which returns the encoded_record", %{
      correct_record: correct_record
    } do
      {:ok, encoded_record} =
        Record.encode(correct_record, :col_taxonomy, tenant: correct_record.collection_id)

      assert encoded_record !== nil

      lookedup_encoded_record =
        EncodedRecord.get_by_record!(encoded_record.id, tenant: correct_record.collection_id)

      assert lookedup_encoded_record !== nil

      assert_map_includes(lookedup_encoded_record, %{
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        tax_domain: "Eukaryota",
        tax_kingdom: "Animalia",
        tax_phylum: "Arthropoda",
        tax_class: "Insecta",
        tax_order: "Hymenoptera",
        tax_family: "Formicidae",
        tax_genus: "Tetramorium",
        tax_taxon_rank: "species",
        tax_taxon_id: "DY5M"
      })

      assert encoded_record.state === :encoded
    end

    test "encode/2 for :col_taxonomy catalog which returns an error for invalid species name", %{
      invalid_record: invalid_record
    } do
      {{:ok, encoded_record}, logs} =
        with_log(fn ->
          Record.encode(invalid_record, :col_taxonomy, tenant: invalid_record.collection_id)
        end)

      encoded_record =
        Record.get_by_id!(encoded_record.id,
          load: [:encoded],
          tenant: invalid_record.collection_id
        )

      assert encoded_record !== nil
      assert encoded_record.state === :failed

      assert encoded_record.encoded == false

      assert logs =~ "with catalog: col_taxonomy failed, due to: "

      assert logs =~
               "[col_taxonomy] Invalid species encoding: \\\"No match found in response body"
    end
  end
end
