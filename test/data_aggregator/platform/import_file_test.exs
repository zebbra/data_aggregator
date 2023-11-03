defmodule DataAggregator.Platform.ImportFileTest do
  use DataAggregator.DataCase

  alias DataAggregator.Data.Record
  alias DataAggregator.Data.Resources.RecordImporter
  alias DataAggregator.Platform.Collection
  alias DataAggregator.Platform.ImportFile

  setup do
    {:ok, collection} = Collection.create(%{name: "Test Collection"})
    %{collection: collection}
  end

  describe "create_from_path" do
    test "with valid file", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      {:ok, import_file} = ImportFile.create_from_path(collection, path)

      columns = import_file.columns |> Enum.map(&{&1.name, &1.type})

      assert columns == [
               {"Age", :string},
               {"Auteur et date ssp", :string},
               {"Autres numéros", :string},
               {"Collecteur", :string},
               {"DAYCOLLECTED", :integer},
               {"ENDOFPERIODDAY", :integer},
               {"ENDOFPERIODMONTH", :integer},
               {"ENDOFPERIODYEAR", :integer},
               {"Espèce", :string},
               {"Famille", :string},
               {"Genre", :string},
               {"LatitudeDecimale", :string},
               {"Localité", :string},
               {"LongitudeDecimale", :string},
               {"MONTHCOLLECTED", :integer},
               {"Numéro scientifique GBIF", :string},
               {"Ordre", :string},
               {"Parties", :string},
               {"Pays", :string},
               {"PrecisionGEO", :string},
               {"Province", :string},
               {"Remarques", :string},
               {"Sexe", :string},
               {"Sous espèce", :string},
               {"Station", :string},
               {"YEARCOLLECTED", :integer}
             ]
    end

    test "with invalid file", %{collection: collection} do
      path = "test/support/fixtures/files/no-recent-events.jpeg"
      {:error, error} = ImportFile.create_from_path(collection, path)

      assert_invalid_path(
        error,
        "path is invalid (Polars Error: invalid utf-8 sequence in csv)"
      )
    end

    test "with non-existing file", %{collection: collection} do
      path = "test/this-file-does-not-exist.csv"
      {:error, error} = ImportFile.create_from_path(collection, path)

      assert_invalid_path(
        error,
        ~r/path is invalid/
      )
    end
  end

  describe "update_mapping" do
    test "with valid file", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      {:ok, import_file} = ImportFile.create_from_path(collection, path)

      params = %{
        columns: [
          %{"name" => "Age", "mapped_to" => "age"},
          %{"name" => "Collecteur", "mapped_to" => ""}
        ]
      }

      {:ok, import_file} = ImportFile.update_mapping(import_file, params)
      columns = import_file.columns |> Enum.map(&{&1.name, &1.type, &1.mapped_to})

      assert columns == [
               {"Age", :string, "age"},
               {"Auteur et date ssp", :string, nil},
               {"Autres numéros", :string, nil},
               {"Collecteur", :string, nil},
               {"DAYCOLLECTED", :integer, nil},
               {"ENDOFPERIODDAY", :integer, nil},
               {"ENDOFPERIODMONTH", :integer, nil},
               {"ENDOFPERIODYEAR", :integer, nil},
               {"Espèce", :string, nil},
               {"Famille", :string, nil},
               {"Genre", :string, nil},
               {"LatitudeDecimale", :string, nil},
               {"Localité", :string, nil},
               {"LongitudeDecimale", :string, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"Numéro scientifique GBIF", :string, nil},
               {"Ordre", :string, nil},
               {"Parties", :string, nil},
               {"Pays", :string, nil},
               {"PrecisionGEO", :string, nil},
               {"Province", :string, nil},
               {"Remarques", :string, nil},
               {"Sexe", :string, nil},
               {"Sous espèce", :string, nil},
               {"Station", :string, nil},
               {"YEARCOLLECTED", :integer, nil}
             ]

      params = %{
        columns: [
          %{name: "Age", mapped_to: ""},
          %{name: "Collecteur", mapped_to: "coll"}
        ]
      }

      {:ok, import_file} = ImportFile.update_mapping(import_file, params)
      columns = import_file.columns |> Enum.map(&{&1.name, &1.type, &1.mapped_to})

      assert columns == [
               {"Age", :string, nil},
               {"Auteur et date ssp", :string, nil},
               {"Autres numéros", :string, nil},
               {"Collecteur", :string, "coll"},
               {"DAYCOLLECTED", :integer, nil},
               {"ENDOFPERIODDAY", :integer, nil},
               {"ENDOFPERIODMONTH", :integer, nil},
               {"ENDOFPERIODYEAR", :integer, nil},
               {"Espèce", :string, nil},
               {"Famille", :string, nil},
               {"Genre", :string, nil},
               {"LatitudeDecimale", :string, nil},
               {"Localité", :string, nil},
               {"LongitudeDecimale", :string, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"Numéro scientifique GBIF", :string, nil},
               {"Ordre", :string, nil},
               {"Parties", :string, nil},
               {"Pays", :string, nil},
               {"PrecisionGEO", :string, nil},
               {"Province", :string, nil},
               {"Remarques", :string, nil},
               {"Sexe", :string, nil},
               {"Sous espèce", :string, nil},
               {"Station", :string, nil},
               {"YEARCOLLECTED", :integer, nil}
             ]
    end
  end

  describe "import_records" do
    @tag run: true
    test "from mapped import file", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"

      # upload a file to a collection
      {:ok, import_file} = ImportFile.create_from_path(collection, path)

      # map the columns to our intern dwc attributes on the record resource
      params = %{
        columns: [
          %{name: "Scientific Name", type: "string", mapped_to: "tax_scientific_name"},
          %{name: "Age", type: "string", mapped_to: "spp_life_stage"},
          %{
            name: "Auteur et date ssp",
            type: "string",
            mapped_to: "tax_scientific_name_authorship"
          },
          %{name: "Autres numéros", type: "string", mapped_to: "occ_associated_occurrences"},
          %{name: "Collecteur", type: "string", mapped_to: "occ_recorded_by"},
          %{name: "DAYCOLLECTED", type: "integer", mapped_to: "eve_day"},
          %{name: "ENDOFPERIODDAY", type: "integer", mapped_to: "eve_end_of_period_day"},
          %{name: "ENDOFPERIODMONTH", type: "integer", mapped_to: "eve_end_of_period_month"},
          %{name: "ENDOFPERIODYEAR", type: "integer", mapped_to: "eve_end_of_period_year"},
          %{name: "Espèce", type: "string", mapped_to: "tax_specific_epithet"},
          %{name: "Famille", type: "string", mapped_to: "tax_family"},
          %{name: "Genre", type: "string", mapped_to: "tax_genus"},
          %{name: "LatitudeDecimale", type: "string", mapped_to: "loc_decimal_latitude"},
          %{name: "Localité", type: "string", mapped_to: "loc_verbatim_locality"},
          %{name: "LongitudeDecimale", type: "string", mapped_to: "loc_decimal_longitude"},
          %{name: "MONTHCOLLECTED", type: "integer", mapped_to: "eve_month"},
          %{
            name: "Numéro scientifique GBIF",
            type: "string",
            mapped_to: "mte_material_entity_id"
          },
          %{name: "Ordre", type: "string", mapped_to: "tax_order"},
          %{name: "Parties", type: "string", mapped_to: "mts_material_sample_type"},
          %{name: "Pays", type: "string", mapped_to: "loc_country"},
          %{name: "PrecisionGEO", type: "string", mapped_to: "loc_georeference_remarks"},
          %{name: "Province", type: "string", mapped_to: "loc_state_province"},
          %{name: "Remarques", type: "string", mapped_to: "occ_occurrence_remarks"},
          %{name: "Sexe", type: "string", mapped_to: "occ_sex"},
          %{name: "Sous espèce", type: "string", mapped_to: "tax_infraspecific_epithet"},
          %{name: "Station", type: "string", mapped_to: "loc_locality"},
          %{name: "YEARCOLLECTED", type: "integer", mapped_to: "eve_year"}
        ]
      }

      # update the import_file with the mapping
      {:ok, import_file} = ImportFile.update_mapping(import_file, params)

      # import the records
      records = RecordImporter.import_records(import_file, params.columns)

      # assert that the records are created returned as proper structs
      for rec <- records do
        case rec do
          {:ok, record} ->
            assert is_struct(record, Record)

          {:error, error} ->
            assert "Unknown error happend #{inspect(error)}"
        end
      end
    end
  end

  defp assert_invalid_path(error, message) when is_binary(message) do
    assert_has_error(
      error.changeset,
      Ash.Error.Invalid,
      &(&1.message == message)
    )
  end

  defp assert_invalid_path(error, message) when is_struct(message, Regex) do
    assert_has_error(
      error.changeset,
      Ash.Error.Invalid,
      &String.match?(&1.message, message)
    )
  end
end
