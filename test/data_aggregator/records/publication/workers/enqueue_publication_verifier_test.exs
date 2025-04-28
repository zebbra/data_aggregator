defmodule DataAggregator.Records.Record.Actions.EnqueuePublicationVerifierTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Publication.Scheduler
  alias DataAggregator.Records.Record

  describe "DataAggregator.Records.Record.enqueue_publication_verifier/2" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      not_published_record = record_fixture(%{publication_status: :in_publication})
      published_record = record_fixture(%{publication_status: :published})

      [
        not_published_record: not_published_record,
        published_record: published_record
      ]
    end

    test "enqueues a runner job with valid record", %{
      not_published_record: not_published_record
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, _job} = Record.enqueue_publication_verifier(not_published_record)

        assert_enqueued(
          worker: Scheduler.PublicationVerifier,
          args: %{id: not_published_record.id, collection_id: not_published_record.collection_id}
        )
      end)
    end

    test "does not enqueue a runner jobs with a record which is already published", %{
      published_record: published_record
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, _job} = Record.enqueue_publication_verifier(published_record)

        assert_enqueued(
          worker: Scheduler.PublicationVerifier,
          args: %{id: published_record.id, collection_id: published_record.collection_id}
        )
      end)
    end
  end
end
