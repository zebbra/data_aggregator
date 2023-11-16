defmodule DataAggregator.ConsumerTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Platform.Publication.Consumer
  alias DataAggregator.Records.Record

  import DataAggregator.ConsumerFixtures
  import DataAggregator.RecordsFixture

  describe "consumer crud tests" do
    @invalid_attrs %{
      name: nil
    }

    test "read!/0 returns all consumers" do
      created = [
        consumer_fixture(),
        consumer_fixture()
      ]

      persisted = Consumer.read!(page: false)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id])
      )
    end

    test "get_by_id!/1 returns the consumer with given id" do
      created = consumer_fixture()
      persisted = Consumer.get_by_id!(created.id)

      assert_structs_equal(created, persisted, [:id])
    end

    test "create/1 creates a consumer with valid data" do
      attrs = %{
        name: "gbif.org"
      }

      assert {:ok, %Consumer{} = _consumer} = Consumer.create(attrs)
    end

    test "create/1 with invalid data returns an error changeset" do
      assert {:error, %Ash.Error.Invalid{}} = Consumer.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the consumer" do
      consumer = consumer_fixture()

      updated_consumer = %{
        name: "gbif.org_2"
      }

      assert {:ok, %Consumer{} = consumer} = Consumer.update(consumer, updated_consumer)

      assert consumer.name == "gbif.org_2"
    end

    test "update/2 with invalid data fails and returns an error changeset" do
      consumer = consumer_fixture()
      assert {:error, %Ash.Error.Invalid{}} = Consumer.update(consumer, @invalid_attrs)
    end

    test "destroy/1 deletes a consumer" do
      consumer = consumer_fixture()
      assert :ok = Consumer.destroy(consumer)
      assert_raise Ash.Error.Query.NotFound, fn -> Consumer.get_by_id!(consumer.id) end
    end

    test "destroy/1 with invalid id fails and returns an error changeset" do
      assert {:error, %Ash.Error.Unknown{}} = Consumer.destroy(%Consumer{id: "invalid"})
    end
  end
end
