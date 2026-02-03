defmodule DataAggregator.Records.Encoding.Actions.BulkEncodeRecordsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.CatalogOfLife, as: CoL
  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.Actions.BulkEncodeRecords
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  describe "run/3" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(CoL.RestAPI, CoL.RestAPIStub)
      stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_col_taxonomy_invalid()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "succeeds a valid record to encode", %{correct_record: correct_record} do
      expect_correct_swiss_species_api_call()

      collection = correct_record.collection

      {:ok, results} = BulkEncodeRecords.run([correct_record.id], collection, tenant: collection)

      assert length(results.successful) == 1
      assert Enum.empty?(results.failed)
      assert hd(results.successful) == correct_record.id

      record = Record.get_by_id!(correct_record.id, tenant: collection)
      assert record.state == :encoded

      encoded_record = EncodedRecord.get_by_record!(record.id, tenant: collection)

      assert_map_includes(encoded_record, %{
        tax_class: "Insecta",
        tax_family: "Formicidae",
        tax_genus: "Tetramorium",
        tax_order: "Hymenoptera",
        tax_phylum: "Arthropoda",
        tax_taxon_id: "DY5M",
        tax_kingdom: "Animalia",
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        tax_accepted_name_usage: "Enantiulus dentigerus (Verhoeff, 1901)",
        tax_taxon_id_ch: 15_311,
        tax_taxon_rank: "SPECIES",
        loc_country: "Switzerland",
        loc_municipality: nil,
        loc_state_province: "Bern",
        loc_continent: "Europe",
        loc_country_code: "CH",
        iucn_redlist_category: "VU"
      })

      # Audit records should exist for all catalogs in order
      audit_records = RecordEncodingResult.filter_by_record!(record.id, tenant: collection)
      assert length(audit_records) == length(Catalog.get_catalogs())

      catalogs_in_order = Enum.map(Enum.reverse(audit_records), & &1.catalog)
      assert catalogs_in_order == Catalog.get_catalogs()
    end

    @tag capture_log: true
    test "succeeds a partial valid record and performs all encodings but sets state to failed", %{
      correct_record: correct_record
    } do
      correct_record = update_record_fixtures!(correct_record, %{loc_country: nil})
      expect_correct_swiss_species_api_call()

      collection = correct_record.collection

      {:ok, results} = BulkEncodeRecords.run([correct_record.id], collection, tenant: collection)

      assert length(results.failed) == 1
      assert Enum.empty?(results.successful)

      record = Record.get_by_id!(correct_record.id, tenant: collection)
      assert record.state == :failed

      encoded_record = EncodedRecord.get_by_record!(record.id, tenant: collection)

      assert_map_includes(encoded_record, %{
        tax_class: "Insecta",
        tax_family: "Formicidae",
        tax_genus: "Tetramorium",
        tax_order: "Hymenoptera",
        tax_phylum: "Arthropoda",
        tax_taxon_id: "DY5M",
        tax_kingdom: "Animalia",
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        tax_accepted_name_usage: "Enantiulus dentigerus (Verhoeff, 1901)",
        tax_taxon_id_ch: 15_311,
        tax_taxon_rank: "SPECIES",
        loc_country: nil,
        loc_municipality: nil,
        loc_state_province: "Bern",
        loc_continent: nil,
        loc_country_code: nil,
        iucn_redlist_category: "VU"
      })

      # All catalogs should have audit records despite the failure
      audit_records = RecordEncodingResult.filter_by_record!(record.id, tenant: collection)
      assert length(audit_records) == length(Catalog.get_catalogs())

      catalogs_in_order = Enum.map(Enum.reverse(audit_records), & &1.catalog)
      assert catalogs_in_order == Catalog.get_catalogs()

      # geo_forward should have an :error audit (loc_country is nil)
      geo_forward_audit = Enum.find(audit_records, &(&1.catalog == :geo_forward))
      assert geo_forward_audit.state == :error
    end

    @tag capture_log: true
    test "when first catalog fails, all subsequent catalogs still run and record is marked as failed" do
      # Make col_taxonomy (first catalog) fail by returning an API error
      expect(CoL.RestAPI, :parse_name, fn _name ->
        {:error, "CoL API unavailable"}
      end)

      expect_correct_swiss_species_api_call()

      record = record_fixture_for_encoding()
      collection = record.collection

      {:ok, results} = BulkEncodeRecords.run([record.id], collection, tenant: collection)

      assert length(results.failed) == 1
      assert Enum.empty?(results.successful)

      failed_id = results.failed |> List.first() |> elem(0)
      assert failed_id == record.id

      record = Record.get_by_id!(record.id, tenant: collection)
      assert record.state == :failed

      # Despite col_taxonomy failing, subsequent catalogs should have run
      encoded_record = EncodedRecord.get_by_record!(record.id, tenant: collection)

      assert encoded_record.loc_country_code == "CH"
      assert encoded_record.loc_continent == "Europe"
      assert encoded_record.tax_accepted_name_usage == "Enantiulus dentigerus (Verhoeff, 1901)"
      assert encoded_record.tax_taxon_id_ch == 15_311
      assert encoded_record.iucn_redlist_category == "VU"

      # Audit records should exist for ALL 7 catalogs, in catalog order
      audit_records = RecordEncodingResult.filter_by_record!(record.id, tenant: collection)
      assert length(audit_records) == length(Catalog.get_catalogs())

      catalogs_in_order = Enum.map(Enum.reverse(audit_records), & &1.catalog)
      assert catalogs_in_order == Catalog.get_catalogs()

      # First catalog (col_taxonomy) should have state :error
      col_taxonomy_audit = Enum.find(audit_records, &(&1.catalog == :col_taxonomy))
      assert col_taxonomy_audit.state == :error

      # Other catalogs should have state :success or :unchanged
      other_audits = Enum.reject(audit_records, &(&1.catalog == :col_taxonomy))

      Enum.each(other_audits, fn audit ->
        assert audit.state in [:success, :unchanged],
               "Expected catalog #{audit.catalog} to have state :success or :unchanged, got #{audit.state}"
      end)
    end
  end
end
