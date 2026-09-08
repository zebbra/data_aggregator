defmodule DataAggregatorWeb.CollectionLive.Record.HelpersTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord
  alias DataAggregatorWeb.CollectionLive.Record.Helpers

  describe "attrs_by_category/2" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      record =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      encoded_record_fixture(%{record: record})

      [collection: collection, record: record]
    end

    test "shows an attribute that only the validation layer carries a value for", %{
      collection: collection,
      record: record
    } do
      refute record.org_organism_id

      # the :validate action is what the validation response import uses
      ValidatedRecord.validate!(
        %{org_organism_id: "ORG-1", record: record, collection: collection},
        tenant: collection
      )

      assert %{org_organism_id: "ORG-1"} =
               ValidatedRecord.get_by_record!(record.id, tenant: collection)

      organism_id =
        record
        |> Helpers.attrs_by_category(collection)
        |> Enum.flat_map(& &1.attributes)
        |> Enum.find(&(&1.name == "organismID"))

      assert organism_id
      assert organism_id.validated == "ORG-1"
    end
  end
end
