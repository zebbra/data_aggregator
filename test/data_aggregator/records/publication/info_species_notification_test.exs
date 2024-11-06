defmodule DataAggregator.Records.Publication.InfoSpeciesNotificationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Gbif
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
        Ash.load!(record1, [:encoded_record]),
        Ash.load!(record2, [:encoded_record]),
        Ash.load!(record3, [:encoded_record]),
        Ash.load!(record4, [:encoded_record]),
        Ash.load!(record5, [:encoded_record])
      ]

      query = %{collection: %{id: %{eq: collection.id}}, tax_kingdom: %{is_nil: false}}

      publication =
        %{
          name: "Publication 1",
          channel: :approval,
          records_query: query,
          collection: collection,
          center: :infofauna
        }
        |> Publication.create!(tenant: collection)
        |> Publication.update_attachment!(Attachment.import_from_path!("test/support/fixtures/files/approval_dwca.zip"))

      [collection: collection, records: records, query: query, publication: publication]
    end

    test "Collection.approve/2 publication has the published dwca file attached", %{
      collection: collection,
      publication: publication
    } do
      query =
        Record
        |> Ash.Query.filter_input(publication.records_query)
        |> Ash.Query.set_tenant(publication.collection)

      {:ok, publication} =
        InfoSpecies.notify(publication, query)

      assert publication.channel == :approval
      assert publication.collection_id == collection.id
      assert publication.attachment_id != nil
    end

    test "Collection.approve/2 all records have an updated last_approval_started_at date", %{
      publication: publication
    } do
      query =
        Record
        |> Ash.Query.filter_input(publication.records_query)
        |> Ash.Query.set_tenant(publication.collection)

      {:ok, _publication} =
        InfoSpecies.notify(publication, query)

      assert {:ok, records} = Record.read(tenant: publication.collection)
      assert length(records) == 5

      Enum.each(records, fn record ->
        assert record.last_approval_started_at !== nil
      end)
    end

    test "notify/2 should fail, wrong channel: :fast_track", %{
      publication: publication
    } do
      publication = Publication.update!(publication, %{channel: :fast_track})

      query =
        Record
        |> Ash.Query.filter_input(publication.records_query)
        |> Ash.Query.set_tenant(publication.collection)

      {:error, "Channel has to be :approval to be published to infospecies"} =
        InfoSpecies.notify(publication, query)

      assert {:ok, records} = Record.read(tenant: publication.collection)
      assert length(records) == 5

      Enum.each(records, fn record ->
        assert record.last_approval_started_at === nil
      end)
    end
  end
end
