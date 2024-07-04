defmodule DataAggregator.Records.Approval.Workers.ApproverTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures
  import DataAggregator.RecordsFixtures

  # alias DataAggregator.Records.Approval

  require Ash.Query

  describe "DataAggregator.Records.Approval.Workers.Approver.perform/1" do
    setup do
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

      approval = approval_fixture()

      [approval: approval, records: records]
    end

    # test "approval run success", %{approval: approval} do
    #   perform_job(Approval.Workers.Approver, %{id: approval.id})

    #   approval = Approval.get_by_id!(approval.id)

    #   assert approval.state == :done
    # end

    # TODO: test if all recordsd are now "approved"
  end
end
