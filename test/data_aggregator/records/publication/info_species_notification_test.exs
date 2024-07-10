defmodule DataAggregator.Records.Publication.InfoSpeciesNotificationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records
  alias DataAggregator.Records.Actions.Approve
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

      [collection: collection, records: records, query: query]
    end

    test "Collection.approve/2 publication has the published dwca file attached", %{
      query: query,
      collection: collection
    } do
      # stub the query of the approval method, because swiss_species records are not present on CI
      # without this all queries asking for swiss_species related records would return 0 records
      stub(Approve, :get_queries, fn _, _ ->
        {query, Ash.Query.filter_input(Record, query)}
      end)

      {:ok, _} = Collection.approve(collection, query)

      {:ok, publications} = Publication.read()

      assert length(publications) == 1

      assert publication = Enum.at(publications, 0)

      assert publication.channel == :approval
      assert publication.collection_id == collection.id
      assert publication.attachment_id != nil
    end

    test "Collection.approve/2 all records have an updated last_approval_started_at date", %{
      query: query,
      collection: collection
    } do
      # stub the query of the approval method, because swiss_species records are not present on CI
      # without this all queries asking for swiss_species related records would return 0 records
      stub(Approve, :get_queries, fn _, _ ->
        {query, Ash.Query.filter_input(Record, query)}
      end)

      {:ok, _} = Collection.approve(collection, query)

      assert {:ok, records} = Record.read()
      assert length(records) == 5

      Enum.each(records, fn record ->
        assert record.last_approval_started_at !== nil
      end)
    end

    test "notify/2 should fail, wrong channel: :fast_track", %{
      query: query,
      collection: collection
    } do
      publication =
        Publication.create!(%{
          name: "Publication 1",
          channel: :fast_track,
          records_query: query,
          collection: collection
        })

      {:error, "Channel has to be :approval to be published to infospecies"} =
        InfoSpecies.notify(publication, publication.records_query)

      assert {:ok, records} = Record.read()
      assert length(records) == 5

      Enum.each(records, fn record ->
        assert record.last_approval_started_at === nil
      end)
    end
  end
end
