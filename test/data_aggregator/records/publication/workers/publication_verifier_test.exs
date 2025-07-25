defmodule DataAggregator.Records.Publication.Scheduler.PublicationVerifierTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Publication.Scheduler.PublicationVerifier

  describe "DataAggregator.Records.Publication.Scheduler.PublicationVerifier.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      not_published_record = record_fixture(%{publication_status: :in_publication})
      published_record = record_fixture(%{publication_status: :published})

      [
        not_published_record: not_published_record,
        published_record: published_record
      ]
    end

    test "succeeds a unpublished record to check if its published on gbif", %{
      not_published_record: not_published_record
    } do
      {:ok, record} =
        perform_job(PublicationVerifier, %{
          id: not_published_record.id,
          collection_id: not_published_record.collection_id,
          user_id: nil
        })

      assert record.publication_status == :published
    end

    test "succeeds a already published record to check if its published on gbif", %{
      published_record: published_record
    } do
      {{:ok, record}, logs} =
        with_log(fn ->
          perform_job(PublicationVerifier, %{
            id: published_record.id,
            collection_id: published_record.collection_id,
            user_id: nil
          })
        end)

      assert record.publication_status == :published

      assert logs =~ ""
    end
  end
end
