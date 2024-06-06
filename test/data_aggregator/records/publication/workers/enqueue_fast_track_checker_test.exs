defmodule DataAggregator.Records.Record.Actions.EnqueueFastTrackCheckerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Publication.Scheduler
  alias DataAggregator.Records.Record

  describe "DataAggregator.Records.Record.enqueue_fast_track_checker/2" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      not_published_record = record_fixture(%{fast_track_status: :in_publication})
      published_record = record_fixture(%{fast_track_status: :published})

      [
        not_published_record: not_published_record,
        published_record: published_record
      ]
    end

    test "enqueues a runner job with valid record", %{
      not_published_record: not_published_record
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, record} = Record.enqueue_fast_track_checker(not_published_record)

        assert record.id == not_published_record.id
        assert record.fast_track_status == :in_publication

        assert_enqueued(
          worker: Scheduler.FastTrackPublicationVerifier,
          args: %{id: record.id}
        )
      end)
    end

    test "does not enqueue a runner jobs with a record which is already published", %{
      published_record: published_record
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, record} = Record.enqueue_fast_track_checker(published_record)

        assert record.id == published_record.id
        assert record.fast_track_status == :published

        assert_enqueued(
          worker: Scheduler.FastTrackPublicationVerifier,
          args: %{id: record.id}
        )
      end)
    end
  end
end
