defmodule DataAggregator.RecordEncodingResultTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.RecordEncodingResultFixture
  import DataAggregator.RecordsFixtures

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Encoding.RecordEncodingResult

  describe "record_encoding_results" do
    @invalid_attrs %{
      catalog: :invalid_catalog
    }

    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      []
    end

    test "read!/0 returns all record_encoding_results" do
      collection = collection_fixture()

      created = [
        record_encoding_result_fixture(%{
          record: record_fixture(%{collection: collection, mte_catalog_number: "record1"})
        }),
        record_encoding_result_fixture(%{
          record: record_fixture(%{collection: collection, mte_catalog_number: "record2"})
        })
      ]

      persisted = RecordEncodingResult.read!(page: false, tenant: collection)

      assert_lists_equal(
        created,
        persisted,
        &assert_structs_equal(&1, &2, [:id, :collection_id])
      )
    end

    test "get_by_id!/1 returns the record_encoding_result with given id" do
      created = record_encoding_result_fixture()
      persisted = RecordEncodingResult.get_by_id!(created.id, tenant: created.collection)

      assert_structs_equal(created, persisted, [:id])
    end

    test "filter_by_record!/1 returns all record_encoding_results for the given collection" do
      record_encoding_result_one = record_encoding_result_fixture()
      record_encoding_result_fixture()

      attrs =
        Map.merge(get_default_attrs(), %{
          record: record_encoding_result_one.record,
          collection: record_encoding_result_one.collection
        })

      created = RecordEncodingResult.create!(attrs, tenant: record_encoding_result_one.collection)

      encoding_result =
        hd(
          RecordEncodingResult.filter_by_record!(record_encoding_result_one.record.id,
            tenant: record_encoding_result_one.collection
          )
        )

      assert_structs_equal(created, encoding_result, [:id, :collection_id])
    end

    test "create/1 with valid data creates a record_encoding_result" do
      record = record_fixture()

      attrs =
        Map.merge(get_default_attrs(), %{
          record: record,
          collection: record.collection
        })

      assert {:ok, %RecordEncodingResult{} = result} =
               RecordEncodingResult.create(attrs, tenant: record.collection)

      record_encoding_result = Ash.load!(result, [:record], tenant: record.collection)

      assert record_encoding_result.record.id == record.id
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Invalid{}} = RecordEncodingResult.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the record_encoding_result" do
      record_encoding_result = record_encoding_result_fixture()

      update_attrs =
        Map.merge(get_default_attrs(), %{
          catalog: :gbif_taxonomy,
          state: :error,
          input: %{tax_taxon_id: 9876},
          output: %{tax_kingdom: "Fungi"}
        })

      assert {:ok, %RecordEncodingResult{} = updated_record_encoding_result} =
               RecordEncodingResult.update(record_encoding_result, update_attrs)

      assert updated_record_encoding_result.id == record_encoding_result.id
      assert updated_record_encoding_result.inserted_at == record_encoding_result.inserted_at
      assert updated_record_encoding_result.updated_at != record_encoding_result.updated_at
      assert updated_record_encoding_result.output == %{"tax_kingdom" => "Fungi"}
      assert updated_record_encoding_result.input == %{"tax_taxon_id" => 9876}
      assert updated_record_encoding_result.state == :error
      assert updated_record_encoding_result.catalog == :gbif_taxonomy
    end

    test "update/2 with invalid data returns error changeset" do
      record_encoding_result = record_encoding_result_fixture()

      assert {:error, %Invalid{}} =
               RecordEncodingResult.update(record_encoding_result, @invalid_attrs)
    end

    test "destroy/1 deletes the record_encoding_result" do
      record_encoding_result = record_encoding_result_fixture()
      assert :ok = RecordEncodingResult.destroy(record_encoding_result)

      assert_raise Invalid, fn ->
        RecordEncodingResult.get_by_id!(record_encoding_result.id,
          tenant: record_encoding_result.collection
        )
      end
    end

    test "destroy/1 with invalid id returns error" do
      assert {:error, %Invalid{}} =
               RecordEncodingResult.destroy(%RecordEncodingResult{id: "invalid"})
    end
  end
end
