defmodule DataAggregator.HelpersTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures
  import DataAggregator.EncodingFixtures
  import DataAggregator.Helpers, only: [maybe_performant_load_record: 3]
  import DataAggregator.RecordEncodingResultFixture
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.ApprovedRecord
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record

  doctest DataAggregator.Records.ImageUpload.Helpers, import: true

  setup do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
    stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

    collection = collection_fixture()
    record = record_fixture(%{collection: collection})
    approved_record = approved_record_fixture(%{collection: collection, record: record})
    encoded_record = encoded_record_fixture(%{record: record})

    record_encoding_result =
      record_encoding_result_fixture(%{record: record, collection: collection})

    [
      collection: collection,
      record: record,
      approved_record: approved_record,
      encoded_record: encoded_record,
      record_encoding_result: record_encoding_result
    ]
  end

  describe "maybe_performant_load_record for approved_record" do
    test "loads record if it is not yet loaded", %{
      collection: tenant,
      approved_record: approved_record
    } do
      approved_record = ApprovedRecord.get_by_id!(approved_record.id, tenant: tenant)
      assert %Ash.NotLoaded{} = approved_record.record

      approved_record =
        maybe_performant_load_record(approved_record, tenant, :collection)

      assert %Record{} = approved_record.record
      assert %Collection{} = approved_record.record.collection
    end

    test "does not load record again if it is already loaded", %{
      collection: tenant,
      approved_record: approved_record
    } do
      approved_record =
        ApprovedRecord.get_by_id!(approved_record.id, tenant: tenant, load: :record)

      assert %Record{} = approved_record.record
      assert %Ash.NotLoaded{} = approved_record.record.collection

      approved_record = maybe_performant_load_record(approved_record, tenant, :collection)
      assert %Record{} = approved_record.record
      assert %Ash.NotLoaded{} = approved_record.record.collection
    end
  end

  describe "maybe_performant_load_record for encoded_record" do
    test "loads record if it is not yet loaded", %{
      collection: tenant,
      encoded_record: encoded_record
    } do
      encoded_record = EncodedRecord.get_by_id!(encoded_record.id, tenant: tenant)
      assert %Ash.NotLoaded{} = encoded_record.record

      encoded_record =
        maybe_performant_load_record(encoded_record, tenant, :collection)

      assert %Record{} = encoded_record.record
      assert %Collection{} = encoded_record.record.collection
    end

    test "does not load record again if it is already loaded", %{
      collection: tenant,
      encoded_record: encoded_record
    } do
      encoded_record =
        EncodedRecord.get_by_id!(encoded_record.id, tenant: tenant, load: :record)

      assert %Record{} = encoded_record.record
      assert %Ash.NotLoaded{} = encoded_record.record.collection

      encoded_record = maybe_performant_load_record(encoded_record, tenant, :collection)
      assert %Record{} = encoded_record.record
      assert %Ash.NotLoaded{} = encoded_record.record.collection
    end
  end

  describe "maybe_performant_load_record for record_encoding_result" do
    test "loads record if it is not yet loaded", %{
      collection: tenant,
      record_encoding_result: record_encoding_result
    } do
      record_encoding_result =
        RecordEncodingResult.get_by_id!(record_encoding_result.id, tenant: tenant)

      assert %Ash.NotLoaded{} = record_encoding_result.record

      record_encoding_result =
        maybe_performant_load_record(record_encoding_result, tenant, :collection)

      assert %Record{} = record_encoding_result.record
      assert %Collection{} = record_encoding_result.record.collection
    end

    test "does not load record again if it is already loaded", %{
      collection: tenant,
      record_encoding_result: record_encoding_result
    } do
      record_encoding_result =
        RecordEncodingResult.get_by_id!(record_encoding_result.id, tenant: tenant, load: :record)

      assert %Record{} = record_encoding_result.record
      assert %Ash.NotLoaded{} = record_encoding_result.record.collection

      record_encoding_result =
        maybe_performant_load_record(record_encoding_result, tenant, :collection)

      assert %Record{} = record_encoding_result.record
      assert %Ash.NotLoaded{} = record_encoding_result.record.collection
    end
  end
end
