defmodule DataAggregator.Records.Approval.Workers.ApproverTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.ApprovedRecord

  describe "DataAggregator.Records.Approval.Workers.Approver.perform/1" do
    setup do
      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      records = [
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "Z-000001287",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "Z-000040298",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "Z-000040297",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "Z-000133354",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "Z-000133355",
          tax_kingdom: "Animalia"
        })
      ]

      approval = approval_fixture()

      [approval: approval, records: records]
    end

    test "Approver.perform/1 approval run success", %{approval: approval} do
      perform_job(Approval.Workers.Approver, %{id: approval.id})

      approval = Approval.get_by_id!(approval.id)

      assert approval.state == :done
    end

    test "Approver.perform/1 all ApprovedRecords are created correctly and have the changed values",
         %{approval: approval} do
      {:ok, approval} = perform_job(Approval.Workers.Approver, %{id: approval.id})

      {:ok, approved_records} = ApprovedRecord.read(page: false)

      assert length(approved_records) == 5

      # ensure all records from the approval layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(approved_records, fn record ->
        assert record.tax_kingdom == "Plantae"
      end)

      assert approval.state == :done
    end

    test "Approver.perform/1 only create ApprovedRecords if the input data is valid",
         %{approval: approval} do
      {{:ok, _approval}, logs} =
        with_log(fn -> perform_job(Approval.Workers.Approver, %{id: approval.id}) end)

      {:ok, approved_records} = ApprovedRecord.read(page: false)

      # we import 25 records but only 5 are valid and raw records exist for them in the db,
      # so the correct amount should be present and the log should warn us appropriate
      assert length(approved_records) == 5
      assert logs =~ "18 invalid row(s) dropped from chunk!"
    end

    test "Approver.perform/1 all affected records are in state :approved", %{approval: approval} do
      {:ok, approval} = perform_job(Approval.Workers.Approver, %{id: approval.id})

      {:ok, approved_records} = ApprovedRecord.read(page: false, load: [:record])

      # ensure all records from the approval layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(approved_records, fn approved_record ->
        assert approved_record.record.approval_status == :approved
      end)

      assert approval.state == :done
    end
  end
end
