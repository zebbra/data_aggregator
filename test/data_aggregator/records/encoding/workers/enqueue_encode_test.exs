defmodule DataAggregator.Records.Record.Actions.EnqueueImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder

  describe "DataAggregator.Records.Record.enqueue_encode/2" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      correct_record = record_fixture_for_encoding()
      invalid_record = record_fixture_for_encoding_gbif_taxonomy_invalid()

      [
        correct_record: correct_record,
        invalid_record: invalid_record,
        collection: correct_record.collection
      ]
    end

    test "enqueues a runner job with valid record", %{
      correct_record: correct_record
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, record} = Record.enqueue_encoder(correct_record)

        assert record.state == :queued

        assert_enqueued(worker: Encoder, args: %{id: correct_record.id})
      end)
    end

    test "enqueues 3 runner jobs with invalid record", %{invalid_record: invalid_record} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, record} = Record.enqueue_encoder(invalid_record)

        assert record.state == :queued

        assert_enqueued(worker: Encoder, args: %{id: record.id})
      end)
    end

    test "set_encoding/1 succeeds if collection is in state idle", %{collection: collection} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, collection} = Collection.set_encoding(collection)

        assert collection.state == :encoding
      end)
    end

    test "set_encoding/1 fails if collection is in state encoding", %{collection: collection} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = Collection.set_encoding!(collection)
        assert_state(collection, :encoding)
      end)
    end

    test "set_encoding/1 fails if collection is in state importing", %{collection: collection} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = Collection.set_importing!(collection)
        assert_state(collection, :importing)
      end)
    end

    test "set_encoding/1 fails if collection is in state exporting", %{collection: collection} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = Collection.set_exporting!(collection)
        assert_state(collection, :exporting)
      end)
    end

    test "set_encoding/1 fails if collection is in state approving", %{collection: collection} do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = Collection.set_approving!(collection)
        assert_state(collection, :approving)
      end)
    end

    test "set_encoding/1 fails if collection is in state set_fast_track_publishing", %{
      collection: collection
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = Collection.set_fast_track_publishing!(collection)
        assert_state(collection, :fast_track_publishing)
      end)
    end

    defp assert_state(collection, state) do
      assert {:error, %Ash.Error.Invalid{}} = Collection.set_encoding(collection)
      collection = Collection.get_by_id!(collection.id)
      assert collection.state == state
    end
  end
end
