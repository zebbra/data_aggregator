defmodule DataAggregator.AddInstitutionCodeEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "encoding of records with " do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      record_fixture = record_fixture_for_add_institution_code_encoding_correct()
      record_fixture_failing = record_fixture_for_add_institution_code_encoding_failing()

      [
        record_fixture: record_fixture,
        record_fixture_failing: record_fixture_failing
      ]
    end

    test "encode/2 for :add_institution_code catalog - successfully adding institution code and id",
         %{
           record_fixture: record_fixture
         } do
      {:ok, record} =
        Record.encode(record_fixture, :add_institution_code, tenant: record_fixture.collection)

      assert record !== nil

      encoded_record = EncodedRecord.get_by_record!(record.id, tenant: record_fixture.collection)
      assert encoded_record !== nil

      assert_map_includes(encoded_record, %{
        oth_institution_id: "5b487a79-76ef-4615-93d9-f4ea25a40c33",
        oth_institution_code: "Z"
      })

      assert record.state === :encoded
    end

    @tag capture_log: true
    test "encode/2 for :add_institution_code catalog - error (no result)",
         %{
           record_fixture_failing: record_fixture_failing
         } do
      {:ok, encoded_record} =
        Record.encode(record_fixture_failing, :add_institution_code, tenant: record_fixture_failing.collection)

      assert_map_includes(encoded_record, %{
        oth_institution_id: nil,
        oth_institution_code: nil
      })

      assert encoded_record.state === :failed
    end
  end
end
