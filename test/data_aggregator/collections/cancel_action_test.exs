defmodule DataAggregator.Collections.CancelActionTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.ImageUploadFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Collection.Workers.EncodingStatePoller
  alias DataAggregator.Records.Collection.Workers.RecordsEnqueuer
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Export.Workers.Exporter
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.ImageUpload.Workers.Mapper
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Workers.Importer
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.Workers.Publisher
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder

  require Ash.Query

  describe "cancel_action/1" do
    @valid_mapping [
      %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
      %{name: "Numéro scientifique GBIF", mapped_to: "mte_catalog_number"}
    ]

    @mapping %{
      "mte_catalog_number" => "Numéro scientifique GBIF",
      "tax_family" => "Famille"
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
      stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

      []
    end

    set_test_cases = [:deleting, :idle]

    for state <- set_test_cases do
      test "raises Ash.Error.Invalid in case collection is in state #{state}" do
        collection = collection_fixture(%{state: unquote(state)})

        assert_raise Ash.Error.Invalid, fn -> Collection.cancel_action!(collection) end
      end
    end

    test "cancels an import job and sets the import to failed and the collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture()

        import =
          collection
          |> Import.create_from_path!(
            "test/support/fixtures/files/museum-dataset-import-example-xs.csv",
            tenant: collection
          )
          |> Import.update_mapping!(@valid_mapping)

        assert {:ok, import} = Import.enqueue_import(import)

        collection = Collection.set_importing!(collection)
        assert collection.state === :importing
        assert import.state === :import_queued

        active_job =
          collection.id |> Job.query_to_imports_by_collection() |> Ash.read_one!()

        assert active_job.state === :available

        assert_enqueued(
          worker: Importer,
          args: %{id: import.id, collection_id: import.collection_id}
        )

        Collection.cancel_action!(collection)
        import = Import.get_by_id!(import.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert import.state === :failed
        assert collection.state === :idle

        cancelled_job = collection.id |> Job.query_to_imports_by_collection() |> Ash.read_one!()
        assert cancelled_job.state === :cancelled
      end)
    end

    test "cancels an import with no active import and no import job and sets collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :importing})

        assert collection.state === :importing

        import =
          collection
          |> Import.create_from_path!(
            "test/support/fixtures/files/museum-dataset-import-example-xs.csv",
            tenant: collection
          )
          |> Import.update_mapping!(@valid_mapping)

        assert import.state === :pending

        refute_enqueued(
          worker: Importer,
          args: %{id: import.id, collection_id: import.collection_id}
        )

        Collection.cancel_action!(collection)

        import = Import.get_by_id!(import.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert import.state === :pending
        assert collection.state === :idle

        refute collection.id |> Job.query_to_imports_by_collection() |> Ash.read_one!()
      end)
    end

    test "cancels an image mapping job and sets the image_upload to failed and the collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture()

        image_upload =
          image_upload_fixture_extracted(collection)

        assert {:ok, image_upload} = ImageUpload.enqueue_mapping(image_upload)

        collection = Collection.set_mapping!(collection)
        assert collection.state === :mapping
        assert image_upload.state === :mapping_queued

        active_job =
          collection.id |> Job.query_to_image_mappings_by_collection() |> Ash.read_one!()

        assert active_job.state === :available

        assert_enqueued(
          worker: Mapper,
          args: %{id: image_upload.id, collection_id: image_upload.collection_id}
        )

        Collection.cancel_action!(collection)
        image_upload = ImageUpload.get_by_id!(image_upload.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert image_upload.state === :mapping_failed
        assert collection.state === :idle

        cancelled_job =
          collection.id |> Job.query_to_image_mappings_by_collection() |> Ash.read_one!()

        assert cancelled_job.state === :cancelled
      end)
    end

    test "cancels an image mapping with no active mapping and no mapping job and sets collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :mapping})

        assert collection.state === :mapping

        image_upload =
          image_upload_fixture_extracted(collection)

        assert image_upload.state === :extracted

        refute_enqueued(
          worker: Mapper,
          args: %{id: image_upload.id, collection_id: image_upload.collection_id}
        )

        Collection.cancel_action!(collection)

        image_upload = ImageUpload.get_by_id!(image_upload.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert image_upload.state === :extracted
        assert collection.state === :idle

        refute collection.id |> Job.query_to_image_mappings_by_collection() |> Ash.read_one!()
      end)
    end

    test "cancels an export job and sets the export to failed and the collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture()

        export =
          Export.create!(
            %{
              name: "export-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
              collection: collection,
              mapping: @mapping,
              records_query: collection.records_to_export_query,
              data_layer: :raw,
              header_source: :custom_selection
            },
            tenant: collection
          )

        assert {:ok, export} = Export.enqueue(export)

        collection = Collection.set_exporting!(collection)
        assert collection.state === :exporting
        assert export.state === :queued

        active_job =
          collection.id |> Job.query_to_exports_by_collection() |> Ash.read_one!()

        assert active_job.state === :available

        assert_enqueued(
          worker: Exporter,
          args: %{id: export.id, collection_id: export.collection_id}
        )

        Collection.cancel_action!(collection)
        export = Export.get_by_id!(export.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert export.state === :failed
        assert collection.state === :idle

        cancelled_job = collection.id |> Job.query_to_exports_by_collection() |> Ash.read_one!()
        assert cancelled_job.state === :cancelled
      end)
    end

    test "cancels an export with no active export and no export job and sets collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :exporting})

        assert collection.state === :exporting

        export =
          Export.create!(
            %{
              name: "export-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
              collection: collection,
              mapping: @mapping,
              records_query: collection.records_to_export_query,
              data_layer: :raw,
              header_source: :custom_selection
            },
            tenant: collection
          )

        assert export.state === :pending

        refute_enqueued(
          worker: Exporter,
          args: %{id: export.id, collection_id: export.collection_id}
        )

        Collection.cancel_action!(collection)

        export = Export.get_by_id!(export.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert export.state === :pending
        assert collection.state === :idle

        refute collection.id |> Job.query_to_exports_by_collection() |> Ash.read_one!()
      end)
    end

    test "cancels an encoding and sets the records to failed and the collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        correct_record = record_fixture_for_encoding()
        collection = correct_record.collection

        assert collection.state === :idle
        assert correct_record.state === :imported

        query = %{collection: %{id: %{eq: collection.id}}}
        Collection.enqueue_encoding!(collection, query)

        collection = Collection.set_encoding!(collection)
        assert collection.state === :encoding

        assert_enqueued(
          worker: RecordsEnqueuer,
          args: %{id: collection.id, collection_id: collection.id, query: query}
        )

        # in testing mode we need to manually poll the worker
        refute_enqueued(worker: EncodingStatePoller)

        correct_record = Record.get_by_id!(correct_record.id)
        assert correct_record.state === :imported

        records_enqueuer_job =
          collection.id |> Job.query_to_encodings_by_collection() |> Ash.read_one!()

        assert records_enqueuer_job.state === :available
        perform_job(RecordsEnqueuer, %{id: collection.id, query: query})

        assert_enqueued(
          worker: Encoder,
          args: %{id: correct_record.id, collection_id: collection.id}
        )

        collection = Collection.get_by_id!(collection.id)
        assert collection.state === :encoding

        correct_record = Record.get_by_id!(correct_record.id)
        assert correct_record.state === :queued

        Collection.cancel_action!(collection)
        correct_record = Record.get_by_id!(correct_record.id)
        collection = Collection.get_by_id!(collection.id)

        assert correct_record.state === :failed
        assert collection.state === :idle

        cancelled_jobs = collection.id |> Job.query_to_encodings_by_collection() |> Ash.read!()
        assert length(cancelled_jobs) === 2

        Enum.each(cancelled_jobs, fn job -> assert job.state === :cancelled end)
      end)
    end

    test "cancels an encoding with no encoding records and no export job and sets collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :encoding})

        assert collection.state === :encoding

        refute_enqueued(worker: RecordsEnqueuer)
        refute_enqueued(worker: EncodingStatePoller)
        refute_enqueued(worker: Encoder)

        Collection.cancel_action!(collection)

        collection = Collection.get_by_id!(collection.id)

        assert collection.state === :idle

        refute collection.id |> Job.query_to_encodings_by_collection() |> Ash.read_one!()
      end)
    end

    test "cancels a fast_track_publication job and sets the fast_track_publication to failed and the collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture()

        query = %{
          collection: %{id: %{eq: collection.id}},
          encoded_record: %{tax_kingdom: %{is_nil: false}}
        }

        publication =
          Publication.create!(
            %{
              name: "Publication Fast Track 1",
              channel: :fast_track,
              records_query: query,
              collection: collection
            },
            tenant: collection
          )

        assert {:ok, publication} = Publication.enqueue(publication)

        collection = Collection.set_fast_track_publishing!(collection)
        assert collection.state === :fast_track_publishing
        assert publication.state === :queued

        active_job =
          collection.id |> Job.query_to_publications_by_collection() |> Ash.read_one!()

        assert active_job.state === :available

        assert_enqueued(
          worker: Publisher,
          args: %{id: publication.id, collection_id: publication.collection_id}
        )

        Collection.cancel_action!(collection)
        publication = Publication.get_by_id!(publication.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert publication.state === :failed
        assert collection.state === :idle

        cancelled_job =
          collection.id |> Job.query_to_publications_by_collection() |> Ash.read_one!()

        assert cancelled_job.state === :cancelled
      end)
    end

    test "cancels a fast_track_publication with no active fast_track_publication and no fast_track_publication job and sets collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :fast_track_publishing})

        assert collection.state === :fast_track_publishing

        query = %{
          collection: %{id: %{eq: collection.id}},
          encoded_record: %{tax_kingdom: %{is_nil: false}}
        }

        publication =
          Publication.create!(
            %{
              name: "Publication Fast Track 1",
              channel: :fast_track,
              records_query: query,
              collection: collection
            },
            tenant: collection
          )

        assert publication.state === :pending

        refute_enqueued(
          worker: Publisher,
          args: %{id: publication.id, collection_id: publication.collection_id}
        )

        Collection.cancel_action!(collection)

        publication = Publication.get_by_id!(publication.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert publication.state === :pending
        assert collection.state === :idle

        refute collection.id |> Job.query_to_publications_by_collection() |> Ash.read_one!()
      end)
    end

    test "cancels an approving job and sets the approving to failed and the collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture()

        query = %{
          collection: %{id: %{eq: collection.id}},
          encoded_record: %{tax_kingdom: %{is_nil: false}}
        }

        publication =
          Publication.create!(
            %{
              name: "Publication Approval 1",
              channel: :approval,
              records_query: query,
              collection: collection,
              center: "infofauna"
            },
            tenant: collection
          )

        publication2 =
          Publication.create!(
            %{
              name: "Publication Approval 2",
              channel: :approval,
              records_query: query,
              collection: collection,
              center: "infofauna"
            },
            tenant: collection
          )

        assert {:ok, publication} = Publication.enqueue(publication)
        assert {:ok, publication2} = Publication.enqueue(publication2)

        collection = Collection.set_approving!(collection)
        assert collection.state === :approving
        assert publication.state === :queued
        assert publication2.state === :queued

        approval_jobs =
          collection.id |> Job.query_to_publications_by_collection() |> Ash.read!()

        assert length(approval_jobs) === 2
        Enum.each(approval_jobs, fn job -> assert job.state === :available end)

        assert_enqueued(
          worker: Publisher,
          args: %{id: publication.id, collection_id: publication.collection_id}
        )

        assert_enqueued(
          worker: Publisher,
          args: %{id: publication2.id, collection_id: publication2.collection_id}
        )

        Collection.cancel_action!(collection)
        publication = Publication.get_by_id!(publication.id, tenant: collection)
        publication2 = Publication.get_by_id!(publication2.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert publication.state === :failed
        assert publication2.state === :failed
        assert collection.state === :idle

        cancelled_jobs =
          collection.id |> Job.query_to_publications_by_collection() |> Ash.read!()

        assert length(cancelled_jobs) === 2
        Enum.each(cancelled_jobs, fn job -> assert job.state === :cancelled end)
      end)
    end

    test "cancels an approving with no active approving and no approving job and sets collection to idle" do
      Oban.Testing.with_testing_mode(:manual, fn ->
        collection = collection_fixture(%{state: :approving})

        assert collection.state === :approving

        query = %{
          collection: %{id: %{eq: collection.id}},
          encoded_record: %{tax_kingdom: %{is_nil: false}}
        }

        publication =
          Publication.create!(
            %{
              name: "Publication Approving 1",
              channel: :approval,
              records_query: query,
              collection: collection,
              center: "infofauna"
            },
            tenant: collection
          )

        assert publication.state === :pending

        refute_enqueued(
          worker: Publisher,
          args: %{id: publication.id, collection_id: publication.collection_id}
        )

        Collection.cancel_action!(collection)

        publication = Publication.get_by_id!(publication.id, tenant: collection)
        collection = Collection.get_by_id!(collection.id)

        assert publication.state === :pending
        assert collection.state === :idle

        refute collection.id |> Job.query_to_publications_by_collection() |> Ash.read_one!()
      end)
    end
  end
end
