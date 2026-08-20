defmodule DataAggregator.Records.Publication.Scheduler.PublicationFinalizerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Publication.Scheduler.PublicationFinalizer
  alias DataAggregator.Records.Record

  setup do
    stub_with(Gbif.RestAPI, RestAPIStub)

    collection = collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
    publication = publication_fixture(%{collection: collection})

    [collection: collection, publication: publication]
  end

  describe "perform/1" do
    test "marks the publication's :publishing records as :published", ctx do
      records = for _ <- 1..3, do: publishing_record(ctx)

      assert :ok = run_finalizer(ctx)

      for record <- records do
        assert reload(record, ctx).publication_status == :published
      end
    end

    test "leaves records of other publications alone", ctx do
      other_publication = publication_fixture(%{collection: ctx.collection})

      mine = publishing_record(ctx)
      theirs = publishing_record(%{ctx | publication: other_publication})

      assert :ok = run_finalizer(ctx)

      assert reload(mine, ctx).publication_status == :published
      assert reload(theirs, ctx).publication_status == :publishing
    end

    test "does not touch records that moved on during the grace period", ctx do
      stale = publishing_record(ctx, :stale)
      failed = publishing_record(ctx, :publication_failed)
      not_published = publishing_record(ctx, :not_published)

      assert :ok = run_finalizer(ctx)

      assert reload(stale, ctx).publication_status == :stale
      assert reload(failed, ctx).publication_status == :publication_failed
      assert reload(not_published, ctx).publication_status == :not_published
    end

    test "is idempotent", ctx do
      record = publishing_record(ctx)

      assert :ok = run_finalizer(ctx)
      assert :ok = run_finalizer(ctx)

      assert reload(record, ctx).publication_status == :published
    end

    test "succeeds when the publication has no published records", ctx do
      assert :ok = run_finalizer(ctx)
    end
  end

  describe "new_job/2" do
    test "reschedules instead of stacking a second job when the publication is re-published",
         ctx do
      Oban.Testing.with_testing_mode(:manual, fn ->
        assert {:ok, first} =
                 Oban.insert(PublicationFinalizer.new_job(ctx.publication.id, ctx.collection.id))

        assert {:ok, second} =
                 Oban.insert(PublicationFinalizer.new_job(ctx.publication.id, ctx.collection.id))

        assert first.id == second.id
        assert second.conflict?
      end)
    end
  end

  # a record that was written into this publication's archive and is still `:publishing`
  defp publishing_record(ctx, status \\ :publishing) do
    record =
      record_fixture(%{
        collection: ctx.collection,
        mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
        publication_status: status
      })

    PublishedRecord.create!(
      %{
        record_id: record.id,
        collection_id: ctx.collection.id,
        publication_id: ctx.publication.id,
        mte_catalog_number: record.mte_catalog_number,
        tax_scientific_name: record.tax_scientific_name
      },
      tenant: ctx.collection
    )

    record
  end

  defp run_finalizer(ctx) do
    PublicationFinalizer.perform(%Oban.Job{
      args: %{"publication_id" => ctx.publication.id, "collection_id" => ctx.collection.id}
    })
  end

  defp reload(record, ctx), do: Record.get_by_id!(record.id, tenant: ctx.collection)
end
