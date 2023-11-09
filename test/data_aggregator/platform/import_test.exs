defmodule DataAggregator.Platform.ImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Platform.Collection
  alias DataAggregator.Platform.Import

  setup do
    {:ok, collection} = Collection.create(%{name: "Test Collection"})
    %{collection: collection}
  end

  describe "create_from_path" do
    test "with valid file", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      {:ok, import} = Import.create_from_path(collection, path)

      columns = import.columns |> Enum.map(&{&1.name, &1.type})

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
               {"LatitudeDecimale", :float},
               {"Localité", :string},
               {"LongitudeDecimale", :float},
               {"MONTHCOLLECTED", :integer},
               {"Numéro scientifique GBIF", :string},
               {"Ordre", :string},
               {"Parties", :string},
               {"Pays", :string},
               {"PrecisionGEO", :string},
               {"Province", :string},
               {"Remarques", :string},
               {"Scientific Name", :string},
               {"Sexe", :string},
               {"Sous espèce", :string},
               {"Station", :string},
               {"YEARCOLLECTED", :integer}
             ]
    end

    test "with invalid file", %{collection: collection} do
      path = "test/support/fixtures/files/no-recent-events.jpeg"
      {:error, error} = Import.create_from_path(collection, path)

      assert_invalid_path(
        error,
        "path is invalid (Polars Error: invalid utf-8 sequence in csv)"
      )
    end

    test "with non-existing file", %{collection: collection} do
      path = "test/this-file-does-not-exist.csv"
      {:error, error} = Import.create_from_path(collection, path)

      assert_invalid_path(
        error,
        ~r/path is invalid/
      )
    end
  end

  describe "update_mapping" do
    test "with valid file", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      {:ok, import} = Import.create_from_path(collection, path)

      mappings = [
        %{"name" => "Age", "mapped_to" => "age"},
        %{"name" => "Collecteur", "mapped_to" => ""}
      ]

      {:ok, import} = Import.update_mapping(import, mappings)
      columns = import.columns |> Enum.map(&{&1.name, &1.type, &1.mapped_to})

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
               {"LatitudeDecimale", :float, nil},
               {"Localité", :string, nil},
               {"LongitudeDecimale", :float, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"Numéro scientifique GBIF", :string, nil},
               {"Ordre", :string, nil},
               {"Parties", :string, nil},
               {"Pays", :string, nil},
               {"PrecisionGEO", :string, nil},
               {"Province", :string, nil},
               {"Remarques", :string, nil},
               {"Scientific Name", :string, nil},
               {"Sexe", :string, nil},
               {"Sous espèce", :string, nil},
               {"Station", :string, nil},
               {"YEARCOLLECTED", :integer, nil}
             ]

      mappings = [
        %{name: "Age", mapped_to: ""},
        %{name: "Collecteur", mapped_to: "coll"}
      ]

      {:ok, import} = Import.update_mapping(import, mappings)
      columns = import.columns |> Enum.map(&{&1.name, &1.type, &1.mapped_to})

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
               {"LatitudeDecimale", :float, nil},
               {"Localité", :string, nil},
               {"LongitudeDecimale", :float, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"Numéro scientifique GBIF", :string, nil},
               {"Ordre", :string, nil},
               {"Parties", :string, nil},
               {"Pays", :string, nil},
               {"PrecisionGEO", :string, nil},
               {"Province", :string, nil},
               {"Remarques", :string, nil},
               {"Scientific Name", :string, nil},
               {"Sexe", :string, nil},
               {"Sous espèce", :string, nil},
               {"Station", :string, nil},
               {"YEARCOLLECTED", :integer, nil}
             ]
    end
  end

  @tag :focus
  describe "import_records" do
    setup %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      %{import: Import.create_from_path!(collection, path)}
    end

    test "from mapped import file", %{import: import} do
      mappings = [
        %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
        %{name: "Age", mapped_to: "spp_life_stage"},
        %{name: "Auteur et date ssp", mapped_to: "tax_scientific_name_authorship"},
        %{name: "Autres numéros", mapped_to: "occ_associated_occurrences"},
        %{name: "Collecteur", mapped_to: "occ_recorded_by"},
        %{name: "DAYCOLLECTED", mapped_to: "eve_day"},
        %{name: "ENDOFPERIODDAY", mapped_to: "eve_end_of_period_day"},
        %{name: "ENDOFPERIODMONTH", mapped_to: "eve_end_of_period_month"},
        %{name: "ENDOFPERIODYEAR", mapped_to: "eve_end_of_period_year"},
        %{name: "Espèce", mapped_to: "tax_specific_epithet"},
        %{name: "Famille", mapped_to: "tax_family"},
        %{name: "Genre", mapped_to: "tax_genus"},
        %{name: "LatitudeDecimale", mapped_to: "loc_decimal_latitude"},
        %{name: "Localité", mapped_to: "loc_verbatim_locality"},
        %{name: "LongitudeDecimale", mapped_to: "loc_decimal_longitude"},
        %{name: "MONTHCOLLECTED", mapped_to: "eve_month"},
        %{name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"},
        %{name: "Ordre", mapped_to: "tax_order"},
        %{name: "Parties", mapped_to: "mts_material_sample_type"},
        %{name: "Pays", mapped_to: "loc_country"},
        %{name: "PrecisionGEO", mapped_to: "loc_georeference_remarks"},
        %{name: "Province", mapped_to: "loc_state_province"},
        %{name: "Remarques", mapped_to: "occ_occurrence_remarks"},
        %{name: "Sexe", mapped_to: "occ_sex"},
        %{name: "Sous espèce", mapped_to: "tax_infraspecific_epithet"},
        %{name: "Station", mapped_to: "loc_locality"},
        %{name: "YEARCOLLECTED", mapped_to: "eve_year"}
      ]

      # update the import with the mapping
      {:ok, import} = Import.update_mapping(import, mappings)

      # import the records
      assert {:ok, import} = Import.import_records(import)
      assert import.records_count == 891
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
