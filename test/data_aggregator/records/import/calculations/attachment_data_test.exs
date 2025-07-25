defmodule DataAggregator.Records.Import.Calculations.AttachmentDataTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @path "test/support/fixtures/files/museum-dataset-import-example.csv"

  @mapping [
    %{name: "Age", mapped_to: "age"},
    %{name: "Auteur et date ssp", mapped_to: "author_and_date_ssp"}
  ]

  setup do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

    {:ok, collection} =
      Collection.create(%{
        type: :zoology,
        name: "Test Collection",
        owner: "Max Powers",
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      })

    %{collection: collection}
  end

  setup %{collection: collection} do
    import =
      collection
      |> Import.create_from_path!(@path, tenant: collection)
      |> Import.update_mapping!(@mapping)

    %{import: import}
  end

  test "original data", %{import: import} do
    {:ok, import} = Ash.load(import, :attachment_data)

    columns =
      Explorer.DataFrame.dtypes(import.attachment_data)

    assert_map_includes(columns, %{
      "Age" => :string,
      "Auteur et date ssp" => :string,
      "Numéro scientifique GBIF" => :string
    })
  end

  test "mapped data", %{import: import} do
    {:ok, import} = Ash.load(import, attachment_data: [mapped: true])

    columns =
      Explorer.DataFrame.dtypes(import.attachment_data)

    assert columns == %{
             "age" => :string,
             "author_and_date_ssp" => :string
           }
  end
end
