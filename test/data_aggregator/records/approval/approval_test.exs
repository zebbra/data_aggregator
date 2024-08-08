defmodule DataAggregator.ApprovalTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.ApprovalFixtures

  alias DataAggregator.Records.Approval

  require Logger

  describe "approvals" do
    @invalid_attrs %{
      file_url: nil
    }

    setup do
      []
    end

    test "read!/0 returns all approvals" do
      created = [
        approval_fixture(),
        approval_fixture()
      ]

      persisted = Approval.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the approval with given id" do
      created = approval_fixture()

      persisted = Approval.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Approval.create(@invalid_attrs)
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

      assert {:error, %Ash.Error.Invalid{}} =
               Approval.update(approval, @invalid_attrs)
    end

    test "destroy/1 deletes the approval" do
      approval = approval_fixture()
      assert :ok = Approval.destroy(approval)
      assert_raise Ash.Error.Query.NotFound, fn -> Approval.get_by_id!(approval.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Invalid{}} = Approval.destroy(%Approval{id: "invalid"})
    end
  end
end
