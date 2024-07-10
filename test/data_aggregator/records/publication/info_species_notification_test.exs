defmodule DataAggregator.Records.Publication.InfoSpeciesNotificationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.InfoSpecies
  alias DataAggregator.Records.Record

  describe "notify infospecies tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection One"})

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          approval_status: :not_approved,
          last_imported_at: nil,
          last_approval_started_at: nil,
          tax_taxon_id: 9368
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          approval_status: :not_approved,
          last_imported_at: nil,
          last_approval_started_at: nil,
          tax_taxon_id: 9368
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          approval_status: :not_approved,
          last_imported_at: nil,
          last_approval_started_at: nil,
          tax_taxon_id: 9368
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          approval_status: :not_approved,
          last_imported_at: nil,
          last_approval_started_at: nil,
          tax_taxon_id: 9368
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom",
          approval_status: :not_approved,
          last_imported_at: nil,
          last_approval_started_at: nil,
          tax_taxon_id: 9368
        })

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})

      records = [
        Records.load!(record1, [:encoded_record]),
        Records.load!(record2, [:encoded_record]),
        Records.load!(record3, [:encoded_record]),
        Records.load!(record4, [:encoded_record]),
        Records.load!(record5, [:encoded_record])
      ]

      query = %{collection: %{id: %{eq: collection.id}}, tax_kingdom: %{is_nil: false}}

      publication =
        Publication.create!(%{
          name: "Publication Fast Track 1",
          channel: :approval,
          records_query: query,
          collection: collection
        })

      [collection: collection, records: records, publication: publication]
    end

    test "verify if :last_approval_started_at is set", %{
      publication: publication,
      collection: collection
    } do
      {:ok, _approval} = Collection.approve(collection, publication.records_query)

      assert records = Record.read!()

      assert length(records) == 5

      Enum.each(records, fn record ->
        assert record.last_approval_started_at !== nil
      end)
    end

    @tag run: true
    test "notify/2 should fail, wrong channel: :fast_track", %{
      publication: publication
    } do
      publication = Publication.update!(publication, %{channel: :fast_track})

      {:error, "Channel has to be :approval to be published to infospecies"} =
        InfoSpecies.notify(publication, publication.records_query)

      assert records = Record.read!()
      assert length(records) == 5

      Enum.each(records, fn record ->
        assert record.last_approval_started_at === nil
      end)
    end
  end
end
