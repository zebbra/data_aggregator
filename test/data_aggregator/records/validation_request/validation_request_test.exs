defmodule DataAggregator.ValidationRequestTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationRequestFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequestRecord
  alias Explorer.DataFrame

  require Ash.Query

  describe "validation request tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
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

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      count_query =
        Record
        |> AshPagify.query_for_filters_map(query)
        |> Ash.Query.set_tenant(collection)

      total_rows_count = Ash.count!(count_query)

      validation_request =
        ValidationRequest.create!(
          %{
            name: "Validation Request",
            center: :infofauna,
            records_query: query,
            total_rows_count: total_rows_count,
            collection: collection
          },
          tenant: collection
        )

      [
        collection: collection,
        records: records,
        validation_request: validation_request
      ]
    end

    test "validate/1 successful", %{
      validation_request: validation_request
    } do
      {:ok, validation_request} =
        Collection.validate(validation_request, tenant: validation_request.collection)

      %{body: body} = Req.get!(validation_request.attachment.url)

      {file_name, file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"validation.csv" end)

      assert file_name
      assert file_content

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(file_content)

      assert DataFrame.n_rows(data_frame) == 5

      assert_lists_equal(DataFrame.names(data_frame), expected_dwc_column_headers())

      assert DataFrame.n_columns(data_frame) == 202
    end

    test "run/1 successful", %{
      validation_request: validation_request
    } do
      {:ok, validation_request} =
        ValidationRequest.run(validation_request)

      validation_request =
        ValidationRequest.get_by_id!(validation_request.id, tenant: validation_request.collection)

      validation_request = Ash.load!(validation_request, [:validation_request_progress])

      assert validation_request.state == :done
      assert validation_request.processed_rows_count == 5
      assert validation_request.total_rows_count == 5
      assert validation_request.validation_request_progress == 1.0
    end

    test "run/1 creates ValidationRequestRecords for changed records", %{
      validation_request: validation_request,
      collection: collection
    } do
      {:ok, _validation_request} = ValidationRequest.run(validation_request)

      vrrs = ValidationRequestRecord.read!(page: false, tenant: collection)

      assert length(vrrs) == 5

      Enum.each(vrrs, fn vrr ->
        assert vrr.data
        assert vrr.collection_id == collection.id
      end)
    end

    test "run/1 updates validation_status to :requested for changed records", %{
      validation_request: validation_request,
      collection: collection
    } do
      {:ok, _validation_request} = ValidationRequest.run(validation_request)

      records = Record.read!(tenant: collection)

      requested_records =
        Enum.filter(records, fn r -> r.validation_status == :requested end)

      assert length(requested_records) == 5
    end

    test "run/1 updates last_validation_started_at for changed records", %{
      validation_request: validation_request,
      collection: collection
    } do
      {:ok, _validation_request} = ValidationRequest.run(validation_request)

      records = Record.read!(tenant: collection)

      Enum.each(records, fn record ->
        assert record.last_validation_started_at
      end)
    end

    test "run/1 skips unchanged records on second validation", %{
      validation_request: validation_request,
      collection: collection
    } do
      # First run — all 5 records should be sent
      {:ok, _validation_request} = ValidationRequest.run(validation_request)

      vrrs_after_first = ValidationRequestRecord.read!(page: false, tenant: collection)
      assert length(vrrs_after_first) == 5

      records_after_first = Record.read!(tenant: collection)
      requested_count = Enum.count(records_after_first, &(&1.validation_status == :requested))
      assert requested_count == 5

      # Second run with same data — no records should change
      query = validation_request.records_query

      validation_request2 =
        ValidationRequest.create!(
          %{
            name: "Validation Request 2",
            center: :infofauna,
            records_query: query,
            total_rows_count: 5,
            collection: collection
          },
          tenant: collection
        )

      {:ok, validation_request2} = ValidationRequest.run(validation_request2)

      # VRRs should still be the same 5 (no new ones, data unchanged)
      vrrs_after_second = ValidationRequestRecord.read!(page: false, tenant: collection)
      assert length(vrrs_after_second) == 5

      # sent_for_validation_count should be 0 since nothing changed
      validation_request2 =
        ValidationRequest.get_by_id!(validation_request2.id, tenant: collection)

      assert validation_request2.sent_for_validation_count == 0
    end

    test "run/1 only sends changed records on second validation after data update", %{
      validation_request: validation_request,
      collection: collection,
      records: records
    } do
      # First run — all 5 records sent
      {:ok, _validation_request} = ValidationRequest.run(validation_request)

      # Modify one record's data so it will be detected as changed
      [record_to_update | _rest] = records

      Record.update!(record_to_update, %{tax_scientific_name: "Modified Species Name"}, tenant: collection)

      # Second run
      query = validation_request.records_query

      validation_request2 =
        ValidationRequest.create!(
          %{
            name: "Validation Request 2",
            center: :infofauna,
            records_query: query,
            total_rows_count: 5,
            collection: collection
          },
          tenant: collection
        )

      {:ok, validation_request2} = ValidationRequest.run(validation_request2)

      validation_request2 =
        ValidationRequest.get_by_id!(validation_request2.id, tenant: collection)

      # Only the modified record should be sent
      assert validation_request2.sent_for_validation_count == 1
    end

    test "validate/1 cleans up only new VRRs on failure, preserving pre-existing ones", %{
      validation_request: validation_request,
      collection: collection,
      records: records
    } do
      # First run succeeds — creates 5 VRRs
      {:ok, _validation_request} = ValidationRequest.run(validation_request)

      vrrs_after_first = ValidationRequestRecord.read!(page: false, tenant: collection)
      assert length(vrrs_after_first) == 5

      # Modify 2 records so they will be detected as changed on the next run
      [record_a, record_b | _rest] = records

      Record.update!(record_a, %{tax_scientific_name: "Changed Species A"}, tenant: collection)

      Record.update!(record_b, %{tax_scientific_name: "Changed Species B"}, tenant: collection)

      # Create a second validation request
      query = validation_request.records_query

      validation_request2 =
        ValidationRequest.create!(
          %{
            name: "Validation Request Fail",
            center: :infofauna,
            records_query: query,
            total_rows_count: 5,
            collection: collection
          },
          tenant: collection
        )

      # Stub to raise during notify — VRRs for the 2 changed records will already
      # have been upserted by the time the error occurs
      stub(Gbif.RestAPI, :get_grscicoll_entity, fn _key, _type ->
        raise "Simulated notification failure"
      end)

      assert {:error, _} =
               Collection.validate(validation_request2, tenant: collection)

      # The 2 changed records had their VRRs upserted (bumping updated_at),
      # then the rollback deleted VRRs with updated_at >= validation_request2.inserted_at.
      # Only the 3 unchanged records' VRRs (with original updated_at) should survive.
      vrrs_after_failure = ValidationRequestRecord.read!(page: false, tenant: collection)
      assert length(vrrs_after_failure) == 3
    end

    test "set_failed/1 can transition from queued state", %{
      validation_request: validation_request,
      collection: collection
    } do
      {:ok, validation_request} =
        ValidationRequest.enqueue(validation_request, %{}, authorize?: false)

      assert validation_request.state == :queued

      {:ok, validation_request} =
        ValidationRequest.set_failed(validation_request)

      assert validation_request.state == :failed
      assert validation_request.finished_at

      persisted =
        ValidationRequest.get_by_id!(validation_request.id, tenant: collection)

      assert persisted.state == :failed
    end
  end
end
