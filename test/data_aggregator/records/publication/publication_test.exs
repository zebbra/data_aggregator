defmodule DataAggregator.PublicationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  import DataAggregator.RecordsFixtures

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record
  alias Explorer.DataFrame

  require Ash.Query

  describe "publication tests" do
    setup do
      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      records = [
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "Animalia"
        }),
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Ecto.UUID.generate()}",
          tax_kingdom: "My Kingdom"
        })
      ]

      [collection: collection, records: records]
    end

    test "publish/1", %{collection: collection, records: _records} do
      query =
        Record
        |> Ash.Query.load(collection: [:id])
        |> Ash.Query.filter(
          collection.id == collection.id and
            not is_nil(tax_kingdom)
        )

      publication =
        Publication.create!(%{
          name: "Publication Fast Track ",
          channel: :fast_track,
          records_query: query,
          collection: collection
        })

      {:ok, publication} = Collection.publish(publication)

      %{body: body} = Req.get!(publication.attachment.url)

      # validating if the core file is correctly created
      {core_file_name, core_file_content} =
        Enum.find(body, fn {file_name, _content} -> file_name == ~c"core.csv" end)

      assert core_file_name != nil
      assert core_file_content != nil

      assert {:ok, %DataFrame{} = data_frame} = DataFrame.load_csv(core_file_content)

      assert_lists_equal(
        data_frame.names,
        DwcaFile.file_header_fields(:core),
        fn a, b -> a == b end
      )

      assert DataFrame.n_rows(data_frame) == 5
    end
  end
end
