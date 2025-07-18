defmodule DataAggregator.Records.ValidationRequestRecordVersionsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.AccountsFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationRequestRecordFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.ValidationRequestRecord
  alias DataAggregator.Records.ValidationRequestRecord.Version, as: ValidationRequestRecordVersion

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

  describe "ValidationRequestRecord versions creation" do
    test "create action generates a version record", %{collection1: collection, record: record} do
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
      assert version.changes != nil
    end

    test "update action generates a version record with changes", %{
      collection1: collection,
      record: record,
      user: user
    } do
      original_data = validation_request_data_fixture(%{"tax_scientific_name" => "Original Name"})

      vrr =
        validation_request_record_fixture(%{
          collection: collection,
          record: record,
          data: original_data
        })

      updated_data = validation_request_data_fixture(%{"tax_scientific_name" => "Updated Name"})
      update_attrs = %{data: updated_data}

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(vrr, update_attrs, actor: user, tenant: collection)

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      assert length(updated_vrr.paper_trail_versions) == 2

      [update_version, create_version] =
        Enum.sort_by(
          updated_vrr.paper_trail_versions,
          & &1.version_inserted_at,
          {:desc, DateTime}
        )

      # Create version
      assert create_version.version_action_type == :create
      assert is_nil(create_version.user_id)
      assert create_version.changes != nil

      # Update version
      assert update_version.version_action_type == :update
      assert update_version.user_id == user.id
      assert update_version.changes["data"] == updated_data
    end

    test "multiple updates create multiple versions", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      # First update
      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{"tax_scientific_name" => "First Update"})},
          actor: user,
          tenant: collection
        )

      # Second update
      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{"tax_scientific_name" => "Second Update"})},
          actor: user,
          tenant: collection
        )

      # Third update
      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{"tax_scientific_name" => "Third Update"})},
          actor: user,
          tenant: collection
        )

      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      # 1 create + 3 updates
      assert length(vrr.paper_trail_versions) == 4

      versions = vrr.paper_trail_versions

      [latest, second, third, create] = versions

      assert latest.version_action_type == :update
      assert latest.changes["data"]["tax_scientific_name"] == "Third Update"

      assert second.version_action_type == :update
      assert second.changes["data"]["tax_scientific_name"] == "Second Update"

      assert third.version_action_type == :update
      assert third.changes["data"]["tax_scientific_name"] == "First Update"

      assert create.version_action_type == :create
      assert create.changes != nil
    end
  end

  describe "ValidationRequestRecord versions relationships" do
    test "version belongs to validation request record", %{
      collection1: collection,
      record: record
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      vrr = Ash.load!(vrr, [paper_trail_versions: [:version_source]], tenant: collection)

      version = hd(vrr.paper_trail_versions)
      assert version.version_source.id == vrr.id
      assert version.version_source.record_id == record.id
    end

    test "version belongs to user when actor is provided", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Updated with User"})},
          actor: user,
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [paper_trail_versions: [:user]], tenant: collection)

      update_version = hd(updated_vrr.paper_trail_versions)

      assert update_version.user.id == user.id
      assert update_version.user.email == user.email
    end

    test "version without actor has nil user_id", %{collection1: collection, record: record} do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{
            data: validation_request_data_fixture(%{tax_scientific_name: "Updated without User"})
          },
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      update_version = hd(updated_vrr.paper_trail_versions)

      assert is_nil(update_version.user_id)
    end

    test "version references are properly constrained by collection", %{
      collection1: collection,
      record: record
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})
      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      version = hd(vrr.paper_trail_versions)
      assert version.collection_id == collection.id
      assert version.version_source_id == vrr.id
    end
  end

  describe "ValidationRequestRecord versions multitenancy" do
    test "versions are properly isolated by collection" do
      collection1 =
        collection_fixture(%{name: "Collection 1", grscicoll_reference: Ecto.UUID.generate()})

      collection2 =
        collection_fixture(%{name: "Collection 2", grscicoll_reference: Ecto.UUID.generate()})

      record1 = record_fixture(%{collection: collection1, mte_catalog_number: "record1"})
      record2 = record_fixture(%{collection: collection2, mte_catalog_number: "record2"})

      vrr1 = validation_request_record_fixture(%{collection: collection1, record: record1})
      vrr2 = validation_request_record_fixture(%{collection: collection2, record: record2})

      # Load versions for each collection
      vrr1 = Ash.load!(vrr1, [:paper_trail_versions], tenant: collection1)
      vrr2 = Ash.load!(vrr2, [:paper_trail_versions], tenant: collection2)

      version1 = hd(vrr1.paper_trail_versions)
      version2 = hd(vrr2.paper_trail_versions)

      # Versions should be isolated by collection
      assert version1.collection_id == collection1.id
      assert version2.collection_id == collection2.id

      # Should not be able to access versions from wrong tenant
      assert ValidationRequestRecordVersion
             |> Ash.Query.filter(id == ^version2.id)
             |> Ash.Query.set_tenant(collection1)
             |> Ash.read!()
             |> length() == 0
    end
  end

  describe "ValidationRequestRecord versions referential integrity" do
    test "deleting validation request record cascades to versions", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      # Create multiple versions
      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Update 1"})},
          actor: user,
          tenant: collection
        )

      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Update 2"})},
          actor: user,
          tenant: collection
        )

      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)
      version_ids = Enum.map(vrr.paper_trail_versions, & &1.id)

      assert length(version_ids) == 3

      # Delete the validation request record
      assert :ok = ValidationRequestRecord.destroy(vrr, tenant: collection)

      assert ValidationRequestRecord
             |> Ash.Query.filter(id == ^vrr.id)
             |> Ash.Query.set_tenant(collection)
             |> Ash.read!()
             |> length() == 0

      [version1, version2, version3] = version_ids

      assert_raise Invalid, fn ->
        ValidationRequestRecordVersion.get_by_id!(version1, tenant: collection)
      end

      assert_raise Invalid, fn ->
        ValidationRequestRecordVersion.get_by_id!(version2, tenant: collection)
      end

      assert_raise Invalid, fn ->
        ValidationRequestRecordVersion.get_by_id!(version3, tenant: collection)
      end
    end

    test "deleting user sets user_id to nil in versions", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Update with User"})},
          actor: user,
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      update_version = hd(updated_vrr.paper_trail_versions)

      assert update_version.user_id == user.id

      # Delete the user
      assert :ok = DataAggregator.Accounts.User.destroy(user)

      # Reload the version - user_id should be nil due to nilify constraint
      reloaded_version =
        ValidationRequestRecordVersion
        |> Ash.Query.filter(id == ^update_version.id)
        |> Ash.Query.set_tenant(collection)
        |> Ash.read!()
        |> hd()

      assert is_nil(reloaded_version.user_id)
    end
  end

  describe "ValidationRequestRecord versions data integrity" do
    test "version stores complete data snapshot", %{
      collection1: collection,
      record: record,
      user: user
    } do
      original_data =
        validation_request_data_fixture(%{
          "tax_scientific_name" => "Original Species",
          "loc_country" => "Switzerland",
          "ext_assertions" => %{"confidence" => 0.8}
        })

      vrr =
        validation_request_record_fixture(%{
          collection: collection,
          record: record,
          data: original_data
        })

      updated_data =
        validation_request_data_fixture(%{
          "tax_scientific_name" => "Updated Species",
          "loc_country" => "Austria",
          "ext_assertions" => %{"confidence" => 0.9, "notes" => "Updated confidence"}
        })

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: updated_data},
          actor: user,
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      update_version = hd(updated_vrr.paper_trail_versions)

      # Version should contain the complete new data
      assert update_version.changes["data"] == updated_data
      assert update_version.changes["data"]["tax_scientific_name"] == "Updated Species"
      assert update_version.changes["data"]["loc_country"] == "Austria"
      assert update_version.changes["data"]["ext_assertions"]["confidence"] == 0.9
      assert update_version.changes["data"]["ext_assertions"]["notes"] == "Updated confidence"
    end

    test "version tracks timestamps correctly", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{tax_scientific_name: "Time Test"})},
          actor: user,
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      [update_version, create_version] = updated_vrr.paper_trail_versions

      # Update version should have a later timestamp
      assert DateTime.after?(
               update_version.version_inserted_at,
               create_version.version_inserted_at
             )
    end

    test "version queries work correctly", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, updated_vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{"tax_scientific_name" => "Query Test"})},
          actor: user,
          tenant: collection
        )

      updated_vrr = Ash.load!(updated_vrr, [:paper_trail_versions], tenant: collection)

      update_version = hd(updated_vrr.paper_trail_versions)

      # Test querying versions by source and collection
      found_versions =
        ValidationRequestRecordVersion
        |> Ash.Query.filter(
          version_source_id == ^update_version.version_source_id and
            collection_id == ^update_version.collection_id
        )
        |> Ash.Query.set_tenant(collection)
        |> Ash.read!()

      # Should find both versions (create and update)
      assert length(found_versions) == 2
      assert Enum.any?(found_versions, &(&1.id == update_version.id))
    end
  end

  describe "ValidationRequestRecord versions CRUD operations" do
    test "can read versions directly", %{collection1: collection, record: record} do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})
      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      version = hd(vrr.paper_trail_versions)

      # Should be able to read the version directly
      direct_version =
        ValidationRequestRecordVersion
        |> Ash.Query.filter(id == ^version.id)
        |> Ash.Query.set_tenant(collection)
        |> Ash.read!()
        |> hd()

      assert direct_version.id == version.id
      assert direct_version.version_action_type == version.version_action_type
    end

    test "can destroy versions", %{collection1: collection, record: record} do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})
      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      version = hd(vrr.paper_trail_versions)

      # Should be able to destroy the version
      assert :ok = ValidationRequestRecordVersion.destroy(version, tenant: collection)

      # Version should be deleted
      assert ValidationRequestRecordVersion
             |> Ash.Query.filter(id == ^version.id)
             |> Ash.Query.set_tenant(collection)
             |> Ash.read!()
             |> length() == 0
    end

    test "versions are sorted by insertion time descending", %{
      collection1: collection,
      record: record,
      user: user
    } do
      vrr = validation_request_record_fixture(%{collection: collection, record: record})

      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{"tax_scientific_name" => "First Update"})},
          actor: user,
          tenant: collection
        )

      {:ok, vrr} =
        ValidationRequestRecord.update(
          vrr,
          %{data: validation_request_data_fixture(%{"tax_scientific_name" => "Second Update"})},
          actor: user,
          tenant: collection
        )

      vrr = Ash.load!(vrr, [:paper_trail_versions], tenant: collection)

      # Versions should be sorted by insertion time descending (newest first)
      timestamps = Enum.map(vrr.paper_trail_versions, & &1.version_inserted_at)
      sorted_timestamps = Enum.sort(timestamps, {:desc, DateTime})

      assert timestamps == sorted_timestamps
    end
  end
end
