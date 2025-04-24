defmodule DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandlerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationResponseFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord
  alias DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandler

  describe "DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandler.perform/1" do
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

      validation_response = validation_response_fixture(%{collection: collection})

      [validation_response: validation_response, records: records]
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 validation response run success", %{
      validation_response: validation_response
    } do
      perform_job(ValidationResponseHandler, %{
        id: validation_response.id,
        collection_id: validation_response.collection_id
      })

      validation_response =
        ValidationResponse.get_by_id!(validation_response.id,
          tenant: validation_response.collection
        )

      assert validation_response.state == :done
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 all ValidatedRecords are created correctly and have the changed values",
         %{validation_response: validation_response} do
      collection = validation_response.collection

      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          collection_id: collection.id
        })

      {:ok, validated_records} = ValidatedRecord.read(page: false, tenant: collection)

      assert length(validated_records) == 5

      # ensure all records from the validation layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(validated_records, fn record ->
        assert record.tax_kingdom == "Plantae"
      end)

      assert validation_response.state == :done
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 only create ValidatedRecords if the input data is valid",
         %{validation_response: validation_response} do
      {{:ok, _validation_response}, logs} =
        with_log(fn ->
          perform_job(ValidationResponseHandler, %{
            id: validation_response.id,
            collection_id: validation_response.collection_id
          })
        end)

      {:ok, validated_records} =
        ValidatedRecord.read(page: false, tenant: validation_response.collection)

      # we import 25 records but only 5 are valid and raw records exist for them in the db,
      # so the correct amount should be present and the log should warn us appropriate
      assert length(validated_records) == 5
      assert logs =~ "18 invalid row(s) dropped from chunk!"
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 all affected records are in state :validated",
         %{
           validation_response: validation_response
         } do
      collection = validation_response.collection

      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          collection_id: validation_response.collection_id
        })

      {:ok, validated_records} =
        ValidatedRecord.read(page: false, load: [:record], tenant: collection)

      # ensure all records from the validation_response layer have now the imported value "Plantae" under tax_kingdom
      Enum.all?(validated_records, fn validated_record ->
        assert validated_record.record.validation_status == :validated
      end)

      assert validation_response.state == :done
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 check if error log is present and correct", %{
      validation_response: validation_response
    } do
      collection = validation_response.collection

      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          collection_id: collection.id
        })

      assert {:ok, validation_response} =
               validation_response.id
               |> ValidationResponse.get_by_id(tenant: collection)
               |> Ash.load([:error_log])

      assert validation_response.rows_count == 23
      assert validation_response.rows_invalid_count == 18
      assert validation_response.rows_validated_count == 5

      # 18 * 2 (collection_id and record_id are missing) + 1 additional
      assert validation_response.rows_error_count == 37

      assert validation_response.error_log != nil

      assert {:ok, data_frame} = Explorer.DataFrame.from_csv(validation_response.error_log.url)

      assert Explorer.DataFrame.n_columns(data_frame) == 6

      # 18 * 2 (collection_id and record_id are missing) + 1 additional
      assert Explorer.DataFrame.n_rows(data_frame) == 37
    end
  end
end
