defmodule DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifierTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier

  describe "DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier.perform/1" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      not_published_record = record_fixture(%{fast_track_status: :in_publication})
      published_record = record_fixture(%{fast_track_status: :published})

      [
        not_published_record: not_published_record,
        published_record: published_record
      ]
    end

    test "succeeds a unpublished record to check if its published on gbif", %{
      not_published_record: not_published_record
    } do
      {:ok, record} = perform_job(FastTrackPublicationVerifier, %{id: not_published_record.id})

      assert record.fast_track_status == :published
    end

    test "succeeds a already published record to check if its published on gbif", %{
      published_record: published_record
    } do
      {{:ok, record}, logs} =
        with_log(fn -> perform_job(FastTrackPublicationVerifier, %{id: published_record.id}) end)

      assert record.fast_track_status == :published

      assert logs =~ ""
    end
  end
end
