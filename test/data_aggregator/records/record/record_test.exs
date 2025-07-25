defmodule DataAggregator.Records.RecordTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordEncodingResultFixture
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Record

  require Logger

  describe "records" do
    @invalid_attrs %{
      mte_catalog_number: nil,
      tax_scientific_name: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all records" do
      collection = collection_fixture()

      created = [
        record_fixture(%{collection: collection, mte_catalog_number: "record1"}),
        record_fixture(%{collection: collection, mte_catalog_number: "record2"})
      ]

      persisted = Record.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the record with given id" do
      created = record_fixture()
      persisted = Record.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with valid data creates a record" do
      collection = collection_fixture()

      attrs = %{
        mte_catalog_number: "record1",
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083",
        collection: collection
      }

      assert {:ok, %Record{} = record} = Record.create(attrs, tenant: collection)

      record = Ash.load!(record, [:paper_trail_versions, :encoded_record], tenant: collection)

      assert length(record.paper_trail_versions) == 1
      assert record.occ_occurrence_id === record.mte_catalog_number
      assert record.oth_basis_of_record === "PreservedSpecimen"

      assert record.encoded_record != nil

      assert record.encoded_record.occ_occurrence_id === record.mte_catalog_number
      assert record.encoded_record.oth_basis_of_record === "PreservedSpecimen"
    end

    test "create/1 with invalid data returns error changeset" do
      collection = collection_fixture()

      assert {:error, %Invalid{}} =
               Record.create(Map.put(@invalid_attrs, :collection, collection), tenant: collection)
    end

    test "update/2 with valid data updates the record" do
      record = record_fixture()

      update_attrs = %{
        mte_catalog_number: "record2",
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
      }

      assert {:ok, %Record{} = _record} = Record.update(record, update_attrs)

      record = Ash.load!(record, [:paper_trail_versions], tenant: record.collection)

      assert length(record.paper_trail_versions) == 1
    end

    test "update/2 with invalid data returns error changeset" do
      collection = collection_fixture()
      record = record_fixture(%{collection: collection})

      assert {:error, %Invalid{}} =
               Record.update(record, Map.put(@invalid_attrs, :collection, collection))
    end

    test "destroy/1 deletes the record" do
      record = record_fixture()
      assert :ok = Record.destroy(record, tenant: record.collection)

      assert_raise Invalid, fn ->
        Record.get_by_id!(record.id, tenant: record.collection)
      end
    end

    test "destroy/1 deletes the record and it's encoded_record" do
      encoded_record = encoded_record_fixture()
      record = encoded_record.record

      assert :ok = Record.destroy(record, tenant: encoded_record.collection)

      assert_raise Invalid, fn ->
        Record.get_by_id!(record.id, tenant: encoded_record.collection)
      end

      assert_raise Invalid, fn ->
        EncodedRecord.get_by_id!(encoded_record.id, tenant: encoded_record.collection)
      end
    end

    test "destroy/1 deletes the record and it's record_encoding_results" do
      record_encoding_result = record_encoding_result_fixture()
      record = record_encoding_result.record

      assert :ok = Record.destroy(record, tenant: record_encoding_result.collection)

      assert_raise Invalid, fn ->
        Record.get_by_id!(record.id, tenant: record_encoding_result.collection)
      end

      assert_raise Invalid, fn ->
        RecordEncodingResult.get_by_id!(record_encoding_result.id,
          tenant: record_encoding_result.collection
        )
      end
    end

    test "destroy/1 deletes the record and it's versions" do
      update_attrs = %{
        tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc042",
        mte_catalog_number: "record42"
      }

      record =
        record_fixture()
        |> Record.update!(update_attrs)
        |> Ash.load!([:paper_trail_versions])

      assert :ok = Record.destroy(record, tenant: record.collection)

      assert_raise Invalid, fn -> Record.get_by_id!(record.id, tenant: record.collection) end

      # TODO: Test versions are actually deleted, which is not easy because they are
      # deleted at the end of the transaction
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = Record.destroy(%Record{id: "invalid"})
    end

    test "destroy/1 deletes the record and its published_record" do
      # Create a record
      record = record_fixture()

      # Create a publication
      publication = publication_fixture(%{collection: record.collection})

      # Create a published record associated with the record
      published_record_attrs = %{
        record_id: record.id,
        collection_id: record.collection_id,
        publication_id: publication.id,
        extra_data: %{},
        mte_catalog_number: "test-catalog-123",
        tax_scientific_name: "Test species"
      }

      assert {:ok, published_record} =
               PublishedRecord.create(published_record_attrs, tenant: record.collection)

      # Verify the published record exists
      assert [tenant: record.collection]
             |> PublishedRecord.read!()
             |> Enum.any?(&(&1.id == published_record.id))

      # Delete the record
      assert :ok = Record.destroy(record, tenant: record.collection)

      # Verify the record is deleted
      assert_raise Invalid, fn ->
        Record.get_by_id!(record.id, tenant: record.collection)
      end

      # Verify the published record is also deleted (cascade)
      refute [tenant: record.collection]
             |> PublishedRecord.read!()
             |> Enum.any?(&(&1.id == published_record.id))
    end

    test "has_one published_record relationship works correctly" do
      # Create two records
      record1 = record_fixture()
      record2 = record_fixture(%{collection: record1.collection, mte_catalog_number: "record2"})

      # Create a publication
      publication = publication_fixture(%{collection: record1.collection})

      # Create published records for each record (unique constraint on record_id)
      published_record_attrs_1 = %{
        record_id: record1.id,
        collection_id: record1.collection_id,
        publication_id: publication.id,
        extra_data: %{},
        mte_catalog_number: "test-catalog-123",
        tax_scientific_name: "Test species 1"
      }

      published_record_attrs_2 = %{
        record_id: record2.id,
        collection_id: record2.collection_id,
        publication_id: publication.id,
        extra_data: %{},
        mte_catalog_number: "test-catalog-456",
        tax_scientific_name: "Test species 2"
      }

      assert {:ok, published_record_1} =
               PublishedRecord.create(published_record_attrs_1, tenant: record1.collection)

      assert {:ok, published_record_2} =
               PublishedRecord.create(published_record_attrs_2, tenant: record1.collection)

      # Load the relationship and verify published record is associated with record1
      record1_with_published = Ash.load!(record1, :published_record, tenant: record1.collection)
      assert record1_with_published.published_record != nil
      assert record1_with_published.published_record.id == published_record_1.id

      # Load the relationship and verify published record is associated with record2
      record2_with_published = Ash.load!(record2, :published_record, tenant: record2.collection)
      assert record2_with_published.published_record != nil
      assert record2_with_published.published_record.id == published_record_2.id

      # Delete record1
      assert :ok = Record.destroy(record1, tenant: record1.collection)

      # Verify record1's published record is deleted (cascade)
      remaining_published_records = PublishedRecord.read!(tenant: record1.collection)
      remaining_ids = Enum.map(remaining_published_records, & &1.id)

      refute published_record_1.id in remaining_ids
      assert published_record_2.id in remaining_ids

      # Delete record2
      assert :ok = Record.destroy(record2, tenant: record2.collection)

      # Verify record2's published record is also deleted (cascade)
      final_published_records = PublishedRecord.read!(tenant: record1.collection)
      final_ids = Enum.map(final_published_records, & &1.id)

      refute published_record_2.id in final_ids
    end
  end

  describe "import action" do
    alias DataAggregator.Records.Import

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection =
        collection_fixture(%{
          type: :zoology,
          name: "My Collection",
          owner: "Max Powers",
          grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
        })

      [collection: collection]
    end

    setup %{collection: collection} do
      import = Import.create!(collection, tenant: collection)
      [import: import]
    end

    test "importing a record", %{import: import} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example",
        some_extra_data: "Extra"
      }

      assert {:ok, record} = Record.import(import, params, tenant: import.collection)
      {:ok, record} = Ash.load(record, [:imports])

      assert_lists_equal(
        record.imports,
        [import],
        &assert_structs_equal(&1, &2, [:id])
      )

      assert_map_includes(record, %{
        collection_id: import.collection_id,
        tax_scientific_name: "Example",
        mte_catalog_number: "ex-123",
        extra_data: %{
          "some_extra_data" => "Extra"
        },
        import_data: %{
          "mte_catalog_number" => "ex-123",
          "tax_scientific_name" => "Example",
          "some_extra_data" => "Extra"
        }
      })

      record = Ash.load!(record, [:paper_trail_versions])

      assert length(record.paper_trail_versions) == 1
    end

    test "updating a record for the same import", %{import: import} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example",
        some_extra_data: "Extra"
      }

      assert {:ok, record} = Record.import(import, params, tenant: import.collection)

      updated_params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Updated Example",
        some_other_extra_data: "Other Extra"
      }

      assert {:ok, updated_record} =
               Record.import(import, updated_params, tenant: import.collection)

      {:ok, updated_record} = Ash.load(updated_record, :imports)

      assert_lists_equal(
        updated_record.imports,
        [import],
        &assert_structs_equal(&1, &2, [:id])
      )

      assert_map_includes(updated_record, %{
        id: record.id,
        collection_id: import.collection_id,
        tax_scientific_name: "Updated Example",
        mte_catalog_number: "ex-123",
        extra_data: %{
          "some_other_extra_data" => "Other Extra"
        }
      })

      record = Ash.load!(record, [:paper_trail_versions])

      assert length(record.paper_trail_versions) == 2
    end

    test "updating a record from another import", %{import: import} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example",
        some_extra_data: "Extra"
      }

      assert {:ok, record} = Record.import(import, params, tenant: import.collection)

      updated_params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Updated Example",
        some_other_extra_data: "Other Extra"
      }

      other_import = Import.create!(record.collection, tenant: record.collection)

      assert {:ok, updated_record} =
               Record.import(other_import, updated_params, tenant: import.collection)

      {:ok, updated_record} = Ash.load(updated_record, :imports)

      assert_lists_equal(
        updated_record.imports,
        [other_import, import],
        &assert_structs_equal(&1, &2, [:id])
      )

      assert_map_includes(updated_record.import_data, %{
        "mte_catalog_number" => "ex-123",
        "tax_scientific_name" => "Updated Example",
        "some_other_extra_data" => "Other Extra"
      })

      record = Ash.load!(record, [:paper_trail_versions])

      assert length(record.paper_trail_versions) == 2
    end

    test "importing a record for another collection", %{import: import} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example"
      }

      record = Record.import!(import, params, tenant: import.collection)

      other_collection =
        collection_fixture(%{
          type: :zoology,
          name: "Another Collection",
          owner: "Max Powers",
          grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa473"
        })

      other_import = Import.create!(other_collection, tenant: other_collection)

      assert {:ok, other_record} = Record.import(other_import, params, tenant: other_collection)

      refute record.id == other_record.id

      assert_map_includes(other_record, %{
        collection_id: other_collection.id,
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example"
      })
    end
  end

  describe "mids levels" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      record = record_fixture()

      [record: record]
    end

    test "mids level 0 - not possible", %{record: record} do
      params = %{
        mte_catalog_number: nil,
        tax_scientific_name: nil
      }

      # due to the fact, that mte_catalog_number and tax_scientific_name are required, the record will not be created
      # and therefore mids 0 is not possible at all
      assert_raise Invalid, fn ->
        record |> update_record_fixtures!(params) |> Ash.load!(:mids_level)
      end
    end

    test "mids level 1", %{record: record} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example"
      }

      record = record |> update_record_fixtures!(params) |> Ash.load!(:mids_level)

      assert record.mids_level == 1
    end

    test "mids level 2", %{record: record} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example",
        mte_part_of_organism: "bla",
        tax_taxon_id: 42
      }

      record = record |> update_record_fixtures!(params) |> Ash.load!(:mids_level)

      assert record.mids_level == 2
    end

    test "mids level 3", %{record: record} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example",
        mte_part_of_organism: "bla",
        tax_taxon_id: 42,
        eve_event_date: "2001-1-1",
        mte_recorded_by: "bla",
        idf_type_status: "bla",
        tax_original_name_usage: "bla",
        loc_continent: "bla",
        loc_country: "bla",
        loc_county: "bla",
        loc_decimal_latitude: 42.42,
        loc_decimal_longitude: 42.42,
        loc_higher_geography: "bla",
        loc_locality: "bla",
        loc_state_province: "bla",
        loc_verbatim_depth: "42",
        loc_verbatim_elevation: "42",
        mte_year_collection_entrance: 2001,
        occ_occurrence_id: "bla"
      }

      record = record |> update_record_fixtures!(params) |> Ash.load!(:mids_level)

      assert record.mids_level == 3
    end

    test "mids level 4", %{record: record} do
      params = %{
        mte_catalog_number: "ex-123",
        tax_scientific_name: "Example",
        mte_part_of_organism: "bla",
        tax_taxon_id: 42,
        eve_event_date: "2001-1-1",
        mte_recorded_by: "bla",
        idf_type_status: "bla",
        tax_original_name_usage: "bla",
        loc_continent: "bla",
        loc_country: "bla",
        loc_county: "bla",
        loc_decimal_latitude: 42.42,
        loc_decimal_longitude: 42.42,
        loc_higher_geography: "bla",
        loc_locality: "bla",
        loc_state_province: "bla",
        loc_verbatim_depth: "42",
        loc_verbatim_elevation: "42",
        mte_year_collection_entrance: 2001,
        occ_occurrence_id: "bla",
        mte_verbatim_label: "bla"
      }

      record = record |> update_record_fixtures!(params) |> Ash.load!(:mids_level)

      assert record.mids_level == 4
    end
  end
end
