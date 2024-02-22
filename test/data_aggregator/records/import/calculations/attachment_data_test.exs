defmodule DataAggregator.Records.Import.Calculations.AttachmentDataTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @path "test/support/fixtures/files/museum-dataset-import-example.csv"

  @mapping [
    %{name: "Age", mapped_to: "age"},
    %{name: "Auteur et date ssp", mapped_to: "author_and_date_ssp"}
  ]

  setup do
    {:ok, collection} =
      Collection.create(%{
        name: "Test Collection",
        owner: "Max Powers",
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      })

    %{collection: collection}
  end

  setup %{collection: collection} do
    import =
      collection
      |> Import.create_from_path!(@path)
      |> Import.update_mapping!(@mapping)

    %{import: import}
  end

  test "original data", %{import: import} do
    {:ok, import} = Records.load(import, :attachment_data)

    columns =
      Explorer.DataFrame.dtypes(import.attachment_data)

    assert_map_includes(columns, %{
      "Age" => :string,
      "Auteur et date ssp" => :string,
      "Numéro scientifique GBIF" => :string
    })
  end

  test "mapped data", %{import: import} do
    {:ok, import} = Records.load(import, attachment_data: [mapped: true])

    columns =
      Explorer.DataFrame.dtypes(import.attachment_data)

    assert columns == %{
             "age" => :string,
             "author_and_date_ssp" => :string
           }
  end
end
