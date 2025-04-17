defmodule DataAggregator.Records.Validation.Workers.ValidaterTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidatedRecord
  alias DataAggregator.Records.Validation
  alias DataAggregator.Records.Validation.Workers.Validater

  describe "DataAggregator.Records.Validation.Workers.Validater.perform/1" do
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

      validation = validation_fixture(%{collection: collection})

      [validation: validation, records: records]
    end

    @tag capture_log: true
    test "Validater.perform/1 validation run success", %{validation: validation} do
      perform_job(Validater, %{id: validation.id, collection_id: validation.collection_id})

      validation = Validation.get_by_id!(validation.id, tenant: validation.collection)

      assert validation.state == :done
    end

    @tag capture_log: true
    test "Validater.perform/1 all ValidatedRecords are created correctly and have the changed values",
         %{validation: validation} do
      collection = validation.collection

      {:ok, validation} =
        perform_job(Validater, %{id: validation.id, collection_id: collection.id})

      {:ok, validated_records} = ValidatedRecord.read(page: false, tenant: collection)

      assert length(validated_records) == 5

      # ensure all records from the validation layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(validated_records, fn record ->
        assert record.tax_kingdom == "Plantae"
      end)

      assert validation.state == :done
    end

    @tag capture_log: true
    test "Validater.perform/1 only create ValidatedRecords if the input data is valid",
         %{validation: validation} do
      {{:ok, _validation}, logs} =
        with_log(fn ->
          perform_job(Validater, %{id: validation.id, collection_id: validation.collection_id})
        end)

      {:ok, validated_records} = ValidatedRecord.read(page: false, tenant: validation.collection)

      # we import 25 records but only 5 are valid and raw records exist for them in the db,
      # so the correct amount should be present and the log should warn us appropriate
      assert length(validated_records) == 5
      assert logs =~ "18 invalid row(s) dropped from chunk!"
    end

    @tag capture_log: true
    test "Validater.perform/1 all affected records are in state :validated", %{
      validation: validation
    } do
      collection = validation.collection

      {:ok, validation} =
        perform_job(Validater, %{id: validation.id, collection_id: validation.collection_id})

      {:ok, validated_records} =
        ValidatedRecord.read(page: false, load: [:record], tenant: collection)

      # ensure all records from the validation layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(validated_records, fn validated_record ->
        assert validated_record.record.validation_status == :validated
      end)

      assert validation.state == :done
    end

    test "Validater.perform/1 check if error log is present and correct", %{
      validation: validation
    } do
      collection = validation.collection

      {:ok, validation} =
        perform_job(Validater, %{id: validation.id, collection_id: collection.id})

      assert {:ok, validation} =
               validation.id |> Validation.get_by_id(tenant: collection) |> Ash.load([:error_log])

      assert validation.rows_count == 23
      assert validation.rows_invalid_count == 18
      assert validation.rows_validated_count == 5

      # 18 * 2 (collection_id and record_id are missing) + 1 additional
      assert validation.rows_error_count == 37

      assert validation.error_log != nil

      assert {:ok, data_frame} = Explorer.DataFrame.from_csv(validation.error_log.url)

      assert Explorer.DataFrame.n_columns(data_frame) == 6

      # 18 * 2 (collection_id and record_id are missing) + 1 additional
      assert Explorer.DataFrame.n_rows(data_frame) == 37
    end
  end
end
