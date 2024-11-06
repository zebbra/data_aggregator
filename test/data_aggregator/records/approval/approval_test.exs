defmodule DataAggregator.ApprovalTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Approval
  alias DataAggregator.RecordsFixtures

  require Logger

  describe "approvals" do
    @invalid_attrs %{
      file_url: nil
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all approvals" do
      collection = RecordsFixtures.collection_fixture()

      created = [
        approval_fixture(%{collection: collection}),
        approval_fixture(%{collection: collection})
      ]

      persisted = Approval.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the approval with given id" do
      created = approval_fixture()

      persisted = Approval.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id, :collection_id])
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = Approval.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the approval" do
      approval = approval_fixture()

      update_attrs = %{
        file_url: "test/support/fixtures/files/NEW-approval_dwca.zip"
      }

      assert {:ok, %Approval{} = approval} = Approval.update(approval, update_attrs)

      assert approval.file_url == "test/support/fixtures/files/NEW-approval_dwca.zip"
    end

    test "update/2 with invalid data returns error changeset" do
      approval = approval_fixture()

      assert {:error, %Invalid{}} =
               Approval.update(approval, @invalid_attrs)
    end

    test "destroy/1 deletes the approval" do
      approval = approval_fixture()
      assert :ok = Approval.destroy(approval, tenant: approval.collection)

      assert_raise Ash.Error.Query.NotFound, fn ->
        Approval.get_by_id!(approval.id, tenant: approval.collection)
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} = Approval.destroy(%Approval{id: "invalid"})
    end
  end
end
