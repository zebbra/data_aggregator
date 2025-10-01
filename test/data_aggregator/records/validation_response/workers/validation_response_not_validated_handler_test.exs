defmodule DataAggregator.Records.ValidationResponse.Workers.ValidationResponseNotValidatedHandlerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: false
  use Mimic

  import DataAggregator.AccountsFixtures, only: [user_fixture: 1]
  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationResponseFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord
  alias DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandler

  require Ash.Query

  describe "DataAggregator.Records.ValidationResponse.Workers.ValidationResponseHandler.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      records = [
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "GBIFCH00993760",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "GBIFCH00993778",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "GBIFCH00993789",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "GBIFCH00993799",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "GBIFCH00995787",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "GBIFCH00995788",
          tax_kingdom: "Plantae"
        })
      ]

      actor = user_fixture(%{roles: [:admin]})

      validation_response =
        validation_response_fixture(
          %{type: :not_validated},
          "test/support/fixtures/files/not_validated.csv"
        )

      [
        validation_response: validation_response,
        records: records,
        collection: collection,
        actor: actor
      ]
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 all ValidatedRecords are created correctly and have the changed values",
         %{validation_response: validation_response, collection: collection, actor: actor} do
      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          user_id: actor.id
        })

      {:ok, validated_records} = ValidatedRecord.read(page: false, tenant: collection)

      {:ok, records} =
        Record
        |> Ash.Query.filter(not is_nil(validation_annotation))
        |> Ash.read(page: false, tenant: collection)

      assert Enum.empty?(validated_records)
      assert length(records) == 4

      # ensure all records ingested by the given file, have the correct :validation_annotation set
      Enum.all?(records, fn record ->
        assert record.validation_annotation == "validation rejection comment"
      end)

      assert validation_response.state == :done

      # check if all updated records have the correct validation_status
      Enum.all?(records, fn record ->
        assert record.validation_status == :not_validated
      end)
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 only update Records if the input data is valid",
         %{validation_response: validation_response, collection: collection, actor: actor} do
      {{:ok, _validation_response}, logs} =
        with_log(fn ->
          perform_job(ValidationResponseHandler, %{
            id: validation_response.id,
            user_id: actor.id
          })
        end)

      {:ok, records} =
        Record
        |> Ash.Query.filter(not is_nil(validation_annotation))
        |> Ash.read(page: false, tenant: collection)

      # we import 6 rows but only 4 are valid,
      # so the correct amount should be present and the log should warn us appropriate
      assert length(records) == 4
      assert logs =~ "[warning] 2 invalid row(s) dropped from chunk!"

      # check if all updated records have the correct validation_status
      Enum.all?(records, fn record ->
        assert record.validation_status == :not_validated
      end)
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 all affected records are in state :not_validated",
         %{
           validation_response: validation_response,
           collection: collection,
           actor: actor
         } do
      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          user_id: actor.id
        })

      assert validation_response.state == :done

      # check if all updated records have the correct validation_status
      {:ok, records} =
        Record
        |> Ash.Query.filter(not is_nil(validation_annotation))
        |> Ash.read(page: false, tenant: collection)

      Enum.all?(records, fn record ->
        assert record.validation_status == :not_validated
      end)
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 check if error log is present and correct", %{
      validation_response: validation_response,
      collection: collection,
      actor: actor
    } do
      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          user_id: actor.id
        })

      assert {:ok, validation_response} =
               validation_response.id
               |> ValidationResponse.get_by_id()
               |> Ash.load([:error_log])

      assert validation_response.rows_count == 6
      assert validation_response.rows_invalid_count == 2
      assert validation_response.rows_validated_count == 4

      assert validation_response.rows_error_count == 2

      assert validation_response.error_log != nil

      assert {:ok, data_frame} = Explorer.DataFrame.from_csv(validation_response.error_log.url)

      assert Explorer.DataFrame.n_columns(data_frame) == 6
      assert Explorer.DataFrame.n_rows(data_frame) == 2
      data_frame |> Explorer.DataFrame.to_rows() |> assert_lists_equal(expected_errors())

      # check if all updated records have the correct validation_status
      {:ok, records} =
        Record
        |> Ash.Query.filter(not is_nil(validation_annotation))
        |> Ash.read(page: false, tenant: collection)

      Enum.all?(records, fn record ->
        assert record.validation_status == :not_validated
      end)
    end

    @tag capture_log: true
    test "ValidationResponseHandler.perform/1 has set the correct :affected_collections on validated_record and :validation_responses on collection",
         %{
           validation_response: validation_response,
           collection: collection,
           actor: actor
         } do
      {:ok, validation_response} =
        perform_job(ValidationResponseHandler, %{
          id: validation_response.id,
          user_id: actor.id
        })

      assert {:ok, validation_response} = Ash.load(validation_response, [:affected_collections])

      assert_lists_equal(
        validation_response.affected_collections,
        [collection],
        &assert_structs_equal(&1, &2, [:id, :name])
      )

      assert {:ok, collection} = Ash.load(collection, [:validation_responses])

      assert_lists_equal(
        collection.validation_responses,
        [validation_response],
        &assert_structs_equal(&1, &2, [:id])
      )

      # check if all updated records have the correct validation_status
      {:ok, records} =
        Record
        |> Ash.Query.filter(not is_nil(validation_annotation))
        |> Ash.read(page: false, tenant: collection)

      Enum.all?(records, fn record ->
        assert record.validation_status == :not_validated
      end)
    end
  end

  defp expected_errors do
    [
      %{
        "catalogNumber" => nil,
        "field" => nil,
        "message" => "Record not found for given catalogNumber and collectionCode",
        "occurrenceID" => nil,
        "scientificName" => nil,
        "value" => nil
      },
      %{
        "catalogNumber" => "GBIFCH00995787",
        "field" => nil,
        "message" => "Record not found for given catalogNumber and collectionCode",
        "occurrenceID" => nil,
        "scientificName" => nil,
        "value" => nil
      }
    ]
  end
end
