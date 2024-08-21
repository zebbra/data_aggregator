defmodule DataAggregator.GbifIUCNRedlistEncodingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  describe "encoding of records with " do
    setup do
      extincted_record = record_fixture_for_encoding_gbif_iucn_redlist_extinct()
      not_evaluated_record = record_fixture_for_encoding_gbif_iucn_redlist_not_evaluated()

      [
        extincted_record: extincted_record,
        not_evaluated_record: not_evaluated_record
      ]
    end

    test "encode/2 for :gbif_iucn_redlist catalog which identified an extincted species", %{
      extincted_record: record
    } do
      {:ok, record} = Record.encode(record, :gbif_iucn_redlist)

      assert record !== nil

      assert {:ok, encoded_record} = EncodedRecord.get_by_record(record.id)

      assert {:ok, record} =
               Record.get_by_id(record.id, load: [:iucn_redlist])

      assert encoded_record.iucn_redlist_category === "EX"

      assert record.iucn_redlist === true

      assert record.state === :encoded
    end

    @tag capture_log: true
    test "encode/2 for :gbif_iucn_redlist catalog which identified an not_evaluated species", %{
      not_evaluated_record: record
    } do
      {:ok, record} = Record.encode(record, :gbif_iucn_redlist)

      assert record !== nil

      assert {:ok, encoded_record} = EncodedRecord.get_by_record(record.id)

      assert {:ok, record} =
               Record.get_by_id(record.id, load: [:iucn_redlist])

      assert encoded_record.iucn_redlist_category === "NE"

      assert record.iucn_redlist === false

      assert record.state === :encoded
    end
  end
end
