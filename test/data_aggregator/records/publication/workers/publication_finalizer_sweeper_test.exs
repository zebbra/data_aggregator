defmodule DataAggregator.Records.Publication.Scheduler.PublicationFinalizerSweeperTest do
  @moduledoc false

  use DataAggregator.DataCase, async: false
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Records
  alias DataAggregator.Records.Publication.Scheduler.PublicationFinalizerSweeper
  alias DataAggregator.Records.Record
  alias DataAggregator.Repo

  setup do
    stub_with(Gbif.RestAPI, RestAPIStub)

    collection = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})

    [collection: collection]
  end

  describe "perform/1" do
    test "finalizes records stranded in :publishing beyond the threshold", %{
      collection: collection
    } do
      record = publishing_record(collection)
      strand(record)

      {result, log} =
        with_log(fn -> PublicationFinalizerSweeper.perform(%Oban.Job{args: %{}}) end)

      assert result == :ok
      assert reload(record, collection).publication_status == :published

      # a stranded record means a finalizer job was lost, which is worth a warning
      assert log =~ "Finalized 1 record(s) stranded in :publishing"
    end

    test "leaves recently published records to the finalizer", %{collection: collection} do
      record = publishing_record(collection)

      {result, log} =
        with_log(fn -> PublicationFinalizerSweeper.perform(%Oban.Job{args: %{}}) end)

      assert result == :ok
      assert reload(record, collection).publication_status == :publishing

      # nothing was stranded, so the sweep stays silent
      refute log =~ "stranded"
    end

    test "leaves other statuses alone however old they are", %{collection: collection} do
      stale = publishing_record(collection, :stale)
      failed = publishing_record(collection, :publication_failed)

      strand(stale)
      strand(failed)

      {result, log} =
        with_log(fn -> PublicationFinalizerSweeper.perform(%Oban.Job{args: %{}}) end)

      assert result == :ok
      assert reload(stale, collection).publication_status == :stale
      assert reload(failed, collection).publication_status == :publication_failed

      refute log =~ "stranded"
    end

    test "sweeps across collections", %{collection: collection} do
      other_collection = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})

      here = publishing_record(collection)
      there = publishing_record(other_collection)

      strand(here)
      strand(there)

      {result, log} =
        with_log(fn -> PublicationFinalizerSweeper.perform(%Oban.Job{args: %{}}) end)

      assert result == :ok
      assert reload(here, collection).publication_status == :published
      assert reload(there, other_collection).publication_status == :published

      assert log =~ "Finalized 2 record(s) stranded in :publishing"
    end
  end

  test "the threshold always trails the grace period" do
    assert Records.publication_stranded_after() > Records.publication_grace_period()
  end

  defp publishing_record(collection, status \\ :publishing) do
    record_fixture(%{
      collection: collection,
      mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
      publication_status: status
    })
  end

  # `updated_at` is not writable through the resource, so age it in the database directly.
  # Matched on the catalog number to sidestep the prefixed UUID encoding.
  defp strand(record) do
    stranded_at =
      DateTime.add(
        DateTime.utc_now(),
        -(Records.publication_stranded_after() + 60_000),
        :millisecond
      )

    Repo.query!("UPDATE records SET updated_at = $1 WHERE mte_catalog_number = $2", [
      stranded_at,
      record.mte_catalog_number
    ])
  end

  defp reload(record, collection), do: Record.get_by_id!(record.id, tenant: collection)
end
