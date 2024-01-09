defmodule DataAggregator.ChangeEventTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records
  alias DataAggregator.Records.ChangeEvent

  import DataAggregator.ChangeEventFixture
  import DataAggregator.RecordsFixtures

  describe "change_events" do
    @invalid_attrs %{
      category: :invalid_category
    }

    test "read!/0 returns all change_events" do
      created = [
        change_event_fixture(),
        change_event_fixture()
      ]

      persisted = ChangeEvent.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the change_event with given id" do
      created = change_event_fixture()
      persisted = ChangeEvent.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 with valid data creates a change_event" do
      record = record_fixture()

      attrs = %{
        value: "new value",
        previous_value: "old value",
        category: :encoding,
        dwc_attribute: :tax_scientific_name,
        record: record
      }

      assert {:ok, %ChangeEvent{} = result} = ChangeEvent.create(attrs)

      change_event = Records.load!(result, [:record])

      assert change_event.record.id == record.id
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = ChangeEvent.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the change_event" do
      change_event = change_event_fixture()

      update_attrs = %{
        category: :import,
        value: "new value 2",
        previous_value: "old value 2",
        dwc_attribute: :tax_family,
        record: record_fixture()
      }

      assert {:ok, %ChangeEvent{} = updated_change_event} =
               ChangeEvent.update(change_event, update_attrs)

      assert updated_change_event.id == change_event.id
      assert updated_change_event.inserted_at == change_event.inserted_at
      assert updated_change_event.updated_at != change_event.updated_at
      assert updated_change_event.category == :import
      assert updated_change_event.value == "new value 2"
      assert updated_change_event.previous_value == "old value 2"
      assert updated_change_event.dwc_attribute == :tax_family
    end

    test "update/2 with invalid data returns error changeset" do
      change_event = change_event_fixture()
      assert {:error, %Ash.Error.Invalid{}} = ChangeEvent.update(change_event, @invalid_attrs)
    end

    test "destroy/1 deletes the change_event" do
      change_event = change_event_fixture()
      assert :ok = ChangeEvent.destroy(change_event)
      assert_raise Ash.Error.Query.NotFound, fn -> ChangeEvent.get_by_id!(change_event.id) end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Ash.Error.Unknown{}} = ChangeEvent.destroy(%ChangeEvent{id: "invalid"})
    end
  end
end
