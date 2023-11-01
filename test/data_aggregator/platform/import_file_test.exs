defmodule DataAggregator.Platform.ImportFileTest do
  use DataAggregator.DataCase
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
               {"GenBank", :string},
               {"Genre", :string},
               {"LatitudeDecimale", :string},
               {"Localité", :string},
               {"LongitudeDecimale", :string},
               {"MONTHCOLLECTED", :integer},
               {"Nb.", :integer},
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
    @tag run: true
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
               {"GenBank", :string, nil},
               {"Genre", :string, nil},
               {"LatitudeDecimale", :string, nil},
               {"Localité", :string, nil},
               {"LongitudeDecimale", :string, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"Nb.", :integer, nil},
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
               {"GenBank", :string, nil},
               {"Genre", :string, nil},
               {"LatitudeDecimale", :string, nil},
               {"Localité", :string, nil},
               {"LongitudeDecimale", :string, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"Nb.", :integer, nil},
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
