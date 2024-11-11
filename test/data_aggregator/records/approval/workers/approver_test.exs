defmodule DataAggregator.Records.Approval.Workers.ApproverTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.Approval.Workers.Approver
  alias DataAggregator.Records.ApprovedRecord

  describe "DataAggregator.Records.Approval.Workers.Approver.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

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

      approval = approval_fixture(%{collection: collection})

      [approval: approval, records: records]
    end

    @tag capture_log: true
    test "Approver.perform/1 approval run success", %{approval: approval} do
      perform_job(Approver, %{id: approval.id, collection_id: approval.collection_id})

      approval = Approval.get_by_id!(approval.id, tenant: approval.collection)

      assert approval.state == :done
    end

    @tag capture_log: true
    test "Approver.perform/1 all ApprovedRecords are created correctly and have the changed values",
         %{approval: approval} do
      collection = approval.collection
      {:ok, approval} = perform_job(Approver, %{id: approval.id, collection_id: collection.id})

      {:ok, approved_records} = ApprovedRecord.read(page: false, tenant: collection)

      assert length(approved_records) == 5

      # ensure all records from the approval layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(approved_records, fn record ->
        assert record.tax_kingdom == "Plantae"
      end)

      assert approval.state == :done
    end

    @tag capture_log: true
    test "Approver.perform/1 only create ApprovedRecords if the input data is valid",
         %{approval: approval} do
      {{:ok, _approval}, logs} =
        with_log(fn ->
          perform_job(Approver, %{id: approval.id, collection_id: approval.collection_id})
        end)

      {:ok, approved_records} = ApprovedRecord.read(page: false, tenant: approval.collection)

      # we import 25 records but only 5 are valid and raw records exist for them in the db,
      # so the correct amount should be present and the log should warn us appropriate
      assert length(approved_records) == 5
      assert logs =~ "18 invalid row(s) dropped from chunk!"
    end

    @tag capture_log: true
    test "Approver.perform/1 all affected records are in state :approved", %{approval: approval} do
      collection = approval.collection

      {:ok, approval} =
        perform_job(Approver, %{id: approval.id, collection_id: approval.collection_id})

      {:ok, approved_records} =
        ApprovedRecord.read(page: false, load: [:record], tenant: collection)

      # ensure all records from the approval layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(approved_records, fn approved_record ->
        assert approved_record.record.approval_status == :approved
      end)

      assert approval.state == :done
    end

    @tag capture_log: true
    test "Approver.perform/1 check if error log is present and correct", %{approval: approval} do
      collection = approval.collection
      {:ok, approval} = perform_job(Approver, %{id: approval.id, collection_id: collection.id})

      assert {:ok, approval} =
               approval.id |> Approval.get_by_id(tenant: collection) |> Ash.load([:error_log])

      assert approval.rows_count == 23
      assert approval.rows_invalid_count == 18
      assert approval.rows_approved_count == 5

      # 18 * 2 (collection_id and record_id are missing) + 1 additional
      assert approval.rows_error_count == 37

      assert approval.error_log != nil

      assert {:ok, data_frame} = Explorer.DataFrame.from_csv(approval.error_log.url)

      assert Explorer.DataFrame.n_columns(data_frame) == 6

      # 18 * 2 (collection_id and record_id are missing) + 1 additional
      assert Explorer.DataFrame.n_rows(data_frame) == 37
    end
  end
end
