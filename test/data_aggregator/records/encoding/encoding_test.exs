defmodule DataAggregator.EncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Record

  import DataAggregator.EncodedRecordsFixtures

  describe "encoding of records with " do
    setup do
      records = [
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding(),
        record_fixture_for_encoding()
      ]

      [records: records]
    end

    test "encode/1 for :gbif_taxonomy catalog which returns all successful encoded_records", %{
      records: records
    } do
      {:ok, encoding_result} = Record.encode(records)

      # add more asserts for encoded fields on encoded_record items
      assert Enum.count(encoding_result.records) == 5
      assert Enum.empty?(encoding_result.errors)
    end
  end
end
