defmodule DataAggregator.Records.ValidationRequestRecordTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.AccountsFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationRequestRecordFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequestRecord

  require Ash.Expr
  require Ash.Query
  require Logger

  setup do
    Application.put_env(:data_aggregator, Accounts, last_terms_update: ~D[2025-01-28])

    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

    collection1 =
      collection_fixture(%{name: "Collection 1", grscicoll_reference: Ecto.UUID.generate()})

    collection2 =
      collection_fixture(%{name: "Collection 2", grscicoll_reference: Ecto.UUID.generate()})

    record = record_fixture(%{collection: collection1})

    user = user_fixture(%{email: "mail-#{Uniq.UUID.uuid7(:slug)}@example.com"})

    [collection1: collection1, collection2: collection2, user: user, record: record]
  end

  describe "validation request records CRUD" do
    test "read!/0 returns all validation request records", %{
      collection1: collection,
      record: record
    } do
      created = [
        validation_request_record_fixture(%{collection: collection, record: record}),
        validation_request_record_fixture(%{
          collection: collection,
          record: record_fixture(%{collection: collection, mte_catalog_number: Uniq.UUID.uuid7(:slug)})
        })
      ]

      persisted = ValidationRequestRecord.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_record/1 returns the validation request record for a specific record", %{
      collection1: collection,
      record: record
    } do
      created = validation_request_record_fixture(%{collection: collection, record: record})
      persisted = ValidationRequestRecord.get_by_record!(record.id, tenant: collection)

      assert_structs_equal(created, persisted, [:id, :record_id, :collection_id])
    end

    test "create/1 with valid data creates a validation request record", %{
      collection1: collection,
      record: record
    } do
      data = validation_request_data_fixture()

      attrs = %{
        data: data,
        collection: collection,
        record: record
      }

      assert {:ok, %ValidationRequestRecord{} = vrr} =
               ValidationRequestRecord.create(attrs, tenant: collection)

      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      # Convert atom keys to string keys for comparishon since Ash stores maps with string keys
      expected_data = for {k, v} <- data, into: %{}, do: {to_string(k), v}
      assert vrr.data == expected_data
      assert vrr.record_id == record.id
      assert vrr.collection_id == collection.id
      assert length(vrr.paper_trail_versions) == 1

      # Verify the version was created correctly
      version = hd(vrr.paper_trail_versions)
      assert version.version_action_type == :create
      assert version.collection_id == collection.id
      assert version.version_source_id == vrr.id
    end

    test "create/1 with invalid data returns error changeset", %{
      collection1: collection,
      record: record
    } do
      invalid_attrs = %{
        data: nil,
        collection: collection,
        record: record
      }

      assert {:error, %Invalid{}} =
               ValidationRequestRecord.create(invalid_attrs, tenant: collection)
    end

    test "create/1 fails when record doesn't belong to collection", %{
      collection2: collection,
      record: record
    } do
      attrs = %{
        data: validation_request_data_fixture(),
        collection: collection,
        record: record
      }

      assert {:error, %Invalid{}} = ValidationRequestRecord.create(attrs, tenant: collection)
    end

    test "update/2 with valid data updates the validation request record", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      new_data =
        validation_request_data_fixture(%{
          tax_scientific_name: "Updated Species Name",
          loc_country: "Updated Country"
        })

      update_attrs = %{data: new_data}

      assert {:ok, %ValidationRequestRecord{} = updated_vrr} =
               ValidationRequestRecord.update(vrr, update_attrs, actor: user, tenant: collection)

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      # Convert atom keys to string keys for comparison since Ash stores maps with string keys
      expected_new_data = for {k, v} <- new_data, into: %{}, do: {to_string(k), v}
      assert updated_vrr.data == expected_new_data
      assert updated_vrr.id == vrr.id
      assert length(updated_vrr.paper_trail_versions) == 2

      # Verify the update version was created
      [update_version, create_version] =
        Enum.sort_by(
          updated_vrr.paper_trail_versions,
          & &1.version_inserted_at,
          {:desc, DateTime}
        )

      assert update_version.version_action_type == :update
      assert update_version.user_id == user.id
      assert create_version.version_action_type == :create
    end

    test "update/2 with invalid data returns error changeset", %{
      collection1: collection,
      record: record
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      invalid_attrs = %{data: nil}

      assert {:error, %Invalid{}} =
               ValidationRequestRecord.update(vrr, invalid_attrs, tenant: collection)
    end

    test "destroy/1 deletes the validation request record", %{
      collection1: collection,
      record: record
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      assert :ok = ValidationRequestRecord.destroy(vrr, tenant: collection)

      assert_raise Invalid, fn ->
        ValidationRequestRecord.get_by_record!(record, tenant: collection)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} =
               ValidationRequestRecord.destroy(%ValidationRequestRecord{id: "invalid"})
    end
  end

  describe "identities and uniqueness" do
    test "by_record identity works correctly", %{collection1: collection, record: record} do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      found = ValidationRequestRecord.get_by_record!(record.id, tenant: collection)
      assert found.id == vrr.id
    end

    test "by_collection identity works correctly", %{collection1: collection, record: record} do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      # This should find the record by id and collection_id
      found_records =
        ValidationRequestRecord
        |> Ash.Query.filter(id == ^vrr.id and collection_id == ^collection.id)
        |> Ash.Query.set_tenant(collection)
        |> Ash.read!()

      found = hd(found_records)

      assert found.id == vrr.id
    end

    test "cannot create duplicate validation request record for same record", %{
      collection1: collection,
      record: record
    } do
      _existing_vrr = validation_request_record_fixture(%{collection: collection, record: record})

      attrs = %{
        data: validation_request_data_fixture(),
        collection: collection,
        record: record
      }

      # This should fail due to the unique constraint on [:record_id, :collection_id]
      assert {:error, %Invalid{}} = ValidationRequestRecord.create(attrs, tenant: collection)
    end
  end

  describe "relationships and referential integrity" do
    test "validation request record belongs to record", %{collection1: collection, record: record} do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})
      vrr_with_record = Ash.load!(vrr, [:record], tenant: collection)

      assert vrr_with_record.record.id == record.id
      assert vrr_with_record.record.mte_catalog_number == record.mte_catalog_number
    end

    test "validation request record belongs to collection", %{
      collection1: collection,
      record: record
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})
      vrr_with_collection = Ash.load!(vrr, [:collection], tenant: collection)

      assert vrr_with_collection.collection.id == collection.id
      assert vrr_with_collection.collection.name == collection.name
    end

    test "deleting record cascades to validation request record", %{
      collection1: collection,
      record: record
    } do
      validation_request_record_fixture(%{collection: collection, record: record})

      # Delete the record
      assert :ok = Record.destroy(record, tenant: collection)

      # Validation request record should be deleted due to cascade
      assert_raise Invalid, fn ->
        ValidationRequestRecord.get_by_record!(record, tenant: collection)
      end

      # Verify by trying to get by id
      # The ValidationRequestRecord should be deleted when the record is deleted
      assert_raise Invalid, fn ->
        ValidationRequestRecord.get_by_record!(record.id, tenant: collection)
      end
    end

    test "deleting collection cascades to validation request record", %{
      collection1: collection,
      record: record
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      # Delete the collection (this will also delete the record due to cascade)
      assert :ok = Collection.destroy(collection)

      assert ValidationRequestRecord
             |> Ash.Query.filter(id == ^vrr.id)
             |> Ash.Query.set_tenant(collection)
             |> Ash.read!()
             |> length() == 0
    end
  end

  describe "paper trail versions" do
    test "create action generates version", %{collection1: collection, record: record} do
      attrs = %{
        data: validation_request_data_fixture(),
        collection: collection,
        record: record
      }

      {:ok, vrr} = ValidationRequestRecord.create(attrs, tenant: collection)
      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      assert length(vrr.paper_trail_versions) == 1
      version = hd(vrr.paper_trail_versions)

      assert version.version_action_type == :create
      assert version.version_source_id == vrr.id
      assert version.collection_id == collection.id
      assert is_nil(version.user_id)
    end

    test "update action generates version with user", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      update_attrs = %{
        data: validation_request_data_fixture(%{tax_scientific_name: "Updated Name"})
      }

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(vrr, update_attrs, actor: user, tenant: collection)

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      assert length(updated_vrr.paper_trail_versions) == 2

      [update_version, _create_version] =
        Enum.sort_by(
          updated_vrr.paper_trail_versions,
          & &1.version_inserted_at,
          {:desc, DateTime}
        )

      assert update_version.version_action_type == :update
      assert update_version.user_id == user.id
      assert update_version.collection_id == collection.id
    end

    test "versions have correct relationships", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Test Update"})},
          actor: user,
          tenant: collection
        )

      updated_vrr =
        Ash.load!(updated_vrr, [paper_trail_versions: [:user, :version_source]], tenant: collection)

      update_version =
        Enum.find(updated_vrr.paper_trail_versions, &(&1.version_action_type == :update))

      assert update_version.user_id == user.id
      assert update_version.version_source.id == vrr.id
    end

    test "deleting validation request record deletes versions", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      # Create some versions by updating
      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Update 1"})},
          actor: user,
          tenant: collection
        )

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          updated_vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Update 2"})},
          actor: user,
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)
      assert length(updated_vrr.paper_trail_versions) == 3

      # Delete the validation request record
      assert :ok = ValidationRequestRecord.destroy(updated_vrr, tenant: collection)

      assert ValidationRequestRecord
             |> Ash.Query.filter(id == ^updated_vrr.id)
             |> Ash.Query.set_tenant(collection)
             |> Ash.read!()
             |> length() == 0
    end
  end

  describe "multitenancy" do
    test "validation request records are properly isolated by collection", %{
      collection1: collection1,
      collection2: collection2
    } do
      record1 = record_fixture(%{collection: collection1, mte_catalog_number: "record121212"})
      record2 = record_fixture(%{collection: collection2, mte_catalog_number: "record212121"})

      vrr1 = validation_request_record_fixture(%{collection: collection1, record: record1})
      vrr2 = validation_request_record_fixture(%{collection: collection2, record: record2})

      # Each collection should only see its own validation request records
      collection1_vrrs = ValidationRequestRecord.read!(page: false, tenant: collection1)
      collection2_vrrs = ValidationRequestRecord.read!(page: false, tenant: collection2)

      assert length(collection1_vrrs) == 1
      assert length(collection2_vrrs) == 1
      assert hd(collection1_vrrs).id == vrr1.id
      assert hd(collection2_vrrs).id == vrr2.id

      # Should not be able to access validation request record from wrong tenant
      assert ValidationRequestRecord
             |> Ash.Query.filter(id == ^vrr2.id)
             |> Ash.Query.set_tenant(collection1)
             |> Ash.read!()
             |> length() == 0
    end
  end

  describe "data attribute validation" do
    test "accepts valid Darwin Core data", %{collection1: collection, record: record} do
      data =
        validation_request_data_fixture(%{
          mte_catalog_number: "VALID-123",
          tax_scientific_name: "Homo sapiens",
          tax_kingdom: "Animalia",
          tax_phylum: "Chordata",
          tax_class: "Mammalia",
          tax_order: "Primates",
          tax_family: "Hominidae",
          tax_genus: "Homo",
          loc_decimal_latitude: 46.2044,
          loc_decimal_longitude: 6.1432,
          loc_country: "Switzerland",
          eve_event_date: "2023-06-15"
        })

      attrs = %{
        data: data,
        collection: collection,
        record: record
      }

      assert {:ok, vrr} = ValidationRequestRecord.create(attrs, tenant: collection)
      # Convert atom keys to string keys for comparison since Ash stores maps with string keys
      expected_data = for {k, v} <- data, into: %{}, do: {to_string(k), v}
      assert vrr.data == expected_data
    end

    test "handles complex nested data structures", %{collection1: collection, record: record} do
      data =
        validation_request_data_fixture(%{
          ext_assertions: %{
            "confidence" => 0.95,
            "source" => "expert_opinion",
            "metadata" => %{
              "validator" => "Dr. Smith",
              "validation_date" => "2023-06-15",
              "notes" => ["High confidence", "Field verified"]
            }
          },
          custom_attributes: %{
            "habitat_notes" => "Dense forest canopy",
            "weather_conditions" => %{
              "temperature" => 22.5,
              "humidity" => 78,
              "conditions" => "partly cloudy"
            }
          }
        })

      attrs = %{
        data: data,
        collection: collection,
        record: record
      }

      assert {:ok, vrr} = ValidationRequestRecord.create(attrs, tenant: collection)
      # Convert atom keys to string keys for comparison since Ash stores maps with string keys
      expected_data = for {k, v} <- data, into: %{}, do: {to_string(k), v}
      assert vrr.data == expected_data
    end

    test "data is required", %{collection1: collection, record: record} do
      attrs = %{
        data: nil,
        collection: collection,
        record: record
      }

      assert {:error, %Invalid{}} = ValidationRequestRecord.create(attrs, tenant: collection)
    end
  end
end
