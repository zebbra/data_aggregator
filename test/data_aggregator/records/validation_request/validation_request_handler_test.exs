defmodule DataAggregator.ValidationRequestHandlerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler

  describe "ValidationRequestHandler.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      records = [
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        tax_kingdom: %{is_nil: false}
      }

      validation_request =
        ValidationRequest.create!(
          %{
            name: "validation-request-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
            center: :infofauna,
            collection: collection,
            records_query: query
          },
          tenant: collection
        )

      [validation_request: validation_request, collection: collection, records: records]
    end

    @tag :skip
    test "perform/1  success", %{validation_request: validation_request, collection: collection} do
      perform_job(ValidationRequestHandler, %{
        id: validation_request.id,
        collection_id: validation_request.collection_id
      })

      validation_request = ValidationRequest.get_by_id!(validation_request.id, tenant: collection)
      assert validation_request.state == :done
      assert validation_request.processed_rows_count == 5
    end
  end
end
