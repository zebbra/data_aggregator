defmodule DataAggregator.ValidationTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias Explorer.DataFrame

  require Ash.Query

  describe "validation tests" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 10.0,
          loc_decimal_longitude: 10.0,
          loc_coordinate_uncertainty_in_meters: 5000.0
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 166.4713889,
          loc_decimal_longitude: 640_000.0,
          loc_coordinate_uncertainty_in_meters: 400.004
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: 4762,
          loc_country: "Switzerland",
          loc_decimal_latitude: 47.27606815,
          loc_decimal_longitude: 9.408043484,
          loc_coordinate_uncertainty_in_meters: 3.03
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

      validation =
        Publication.create!(
          %{
            name: "Publication Fast Track 2",
            channel: :validation,
            center: :infofauna,
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      [
        collection: collection,
        records: records,
        validation: validation
      ]
    end

    test "validate/1 successful", %{
      validation: validation
    } do
      {:ok, validation} = Collection.validate(validation, tenant: validation.collection)

      %{body: body} = Req.get!(validation.attachment.url)
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

      rows = DataFrame.to_rows(data_frame)

      transformed_attributes =
        Enum.map(
          rows,
          &Map.take(&1, [
            "decimalLongitude",
            "decimalLatitude",
            "coordinateUncertaintyInMeters"
          ])
        )

      # we expect the data to not be rounded
      # because the validation is not a publication (where rounding is applied on swiss species records)
      transformed_expected = [
        %{
          "decimalLatitude" => 10.0,
          "decimalLongitude" => 10.0,
          "coordinateUncertaintyInMeters" => 5000.0
        },
        %{
          "decimalLatitude" => 166.4713889,
          "decimalLongitude" => 640_000.0,
          "coordinateUncertaintyInMeters" => 400.004
        },
        %{
          "decimalLatitude" => 47.27606815,
          "decimalLongitude" => 9.408043484,
          "coordinateUncertaintyInMeters" => 3.03
        },
        %{
          "decimalLatitude" => nil,
          "decimalLongitude" => nil,
          "coordinateUncertaintyInMeters" => nil
        },
        %{
          "decimalLatitude" => nil,
          "decimalLongitude" => nil,
          "coordinateUncertaintyInMeters" => nil
        }
      ]

      assert_lists_equal(transformed_expected, transformed_attributes)
    end

    @tag capture_log: true
    test "validate/1 fails with invalid center", %{
      validation: validation
    } do
      validation = Map.put(validation, :center, :not_existing_center)

      {:error, _error} =
        Collection.validate(validation, tenant: validation.collection)
    end
  end
end
