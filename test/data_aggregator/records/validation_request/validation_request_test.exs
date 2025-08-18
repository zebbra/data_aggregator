defmodule DataAggregator.ValidationRequestTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.ValidationRequestFixtures

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias Explorer.DataFrame

  require Ash.Query

  describe "validation request tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})

      records = [
        Ash.load!(record1, [:encoded_record]),
        Ash.load!(record2, [:encoded_record]),
        Ash.load!(record3, [:encoded_record]),
        Ash.load!(record4, [:encoded_record]),
        Ash.load!(record5, [:encoded_record])
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      count_query =
        Record
        |> AshPagify.query_for_filters_map(query)
        |> Ash.Query.set_tenant(collection)

      total_rows_count = Ash.count!(count_query)

      validation_request =
        ValidationRequest.create!(
          %{
            name: "Validation Request",
            center: :infofauna,
            records_query: query,
            total_rows_count: total_rows_count,
            collection: collection
          },
          tenant: collection
        )

      [
        collection: collection,
        records: records,
        validation_request: validation_request
      ]
    end

    test "validate/1 successful", %{
      validation_request: validation_request
    } do
      {:ok, validation_request} =
        Collection.validate(validation_request, tenant: validation_request.collection)

      %{body: body} = Req.get!(validation_request.attachment.url)

      {file_name, file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"validation.csv" end)

      assert file_name != nil
      assert file_content != nil

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(file_content)

      assert DataFrame.n_rows(data_frame) == 5

      assert_lists_equal(DataFrame.names(data_frame), expected_dwc_column_headers())

      assert DataFrame.n_columns(data_frame) == 202
    end

    test "run/1 successful", %{
      validation_request: validation_request
    } do
      {:ok, validation_request} =
        ValidationRequest.run(validation_request)

      validation_request =
        ValidationRequest.get_by_id!(validation_request.id, tenant: validation_request.collection)

      validation_request = Ash.load!(validation_request, [:validation_request_progress])

      assert validation_request.state == :done
      assert validation_request.processed_rows_count == 5
      assert validation_request.total_rows_count == 5
      assert validation_request.validation_request_progress == 1.0
    end
  end
end
