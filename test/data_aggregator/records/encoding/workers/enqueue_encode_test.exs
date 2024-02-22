defmodule DataAggregator.Records.Record.Actions.EnqueueImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Records.Record

  describe "DataAggregator.Records.Record.enqueue_encode/2" do
    setup do
      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_gbif_taxonomy_invalid()

      [
        correct_record: correct_record,
        invalid_record: invalid_record
      ]
    end

    test "enqueues a runner job with valid record", %{
      correct_record: correct_record
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, record} = Record.enqueue_encoder(correct_record)

        assert record.state == :queued

        assert_enqueued(worker: Record.Workers.Encoder, args: %{id: correct_record.id})
      end)
    end

    test "enqueues 3 runner jobs with invalid record", %{invalid_record: invalid_record} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, record} = Record.enqueue_encoder(invalid_record)

        assert record.state == :queued

        assert_enqueued(worker: Record.Workers.Encoder, args: %{id: record.id})
      end)
    end
  end
end
