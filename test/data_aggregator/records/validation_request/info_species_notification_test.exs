defmodule DataAggregator.InfoSpeciesNotificationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.InfoSpecies

  describe "notify infospecies tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection One"})

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          validation_status: :not_validated,
          last_imported_at: nil,
          last_validation_started_at: nil,
          tax_taxon_id: "9368"
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          validation_status: :not_validated,
          last_imported_at: nil,
          last_validation_started_at: nil,
          tax_taxon_id: "9368"
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          validation_status: :not_validated,
          last_imported_at: nil,
          last_validation_started_at: nil,
          tax_taxon_id: "9368"
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          validation_status: :not_validated,
          last_imported_at: nil,
          last_validation_started_at: nil,
          tax_taxon_id: "9368"
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom",
          validation_status: :not_validated,
          last_imported_at: nil,
          last_validation_started_at: nil,
          tax_taxon_id: "9368"
        })

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})

      query = %{collection: %{id: %{eq: collection.id}}, tax_kingdom: %{is_nil: false}}

      validation_request =
        %{
          name: "Validation Request",
          center: :infofauna,
          records_query: query,
          collection: collection
        }
        |> ValidationRequest.create!(tenant: collection)
        |> ValidationRequest.update_attachment!(
          Attachment.import_from_path!(
            "test/support/fixtures/files/validation_dwca.zip",
            collection
          )
        )

      [
        collection: collection,
        validation_request: validation_request
      ]
    end

    test "InfoSpecies.notify/2 publication has the published dwca file attached", %{
      collection: collection,
      validation_request: validation_request
    } do
      {:ok, validation_request} =
        InfoSpecies.notify(validation_request, 2)

      assert validation_request.collection_id == collection.id
      assert validation_request.attachment_id
    end
  end
end
