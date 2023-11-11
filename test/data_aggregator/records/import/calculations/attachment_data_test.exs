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
    {:ok, collection} = Collection.create(%{name: "Test Collection", owner: "Max Powers"})
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

    import.attachment_data
    |> Explorer.DataFrame.dtypes()
    |> assert_map_includes(%{
      "Age" => :string,
      "Auteur et date ssp" => :string
    })
  end

  test "mapped data", %{import: import} do
    {:ok, import} = Records.load(import, attachment_data: [mapped: true])

    import.attachment_data
    |> Explorer.DataFrame.dtypes()
    |> assert_map_includes(%{
      "age" => :string,
      "author_and_date_ssp" => :string
    })
  end
end
