defmodule DataAggregator.Platform.ImportFileTest do
  @moduledoc false

  use DataAggregator.DataCase
  alias DataAggregator.Platform.Collection
  alias DataAggregator.Platform.ImportFile

  describe "create_from_path" do
    test "import valid file from path" do
      {:ok, collection} = Collection.create(%{name: "Test Collection"})

      {:ok, import_file} =
        ImportFile.create_from_path(
          collection,
          "test/support/fixtures/files/museum-dataset-import-example.csv"
        )

      assert import_file.columns == [
               "Age",
               "Auteur et date sp.",
               "Auteur et date ssp",
               "Autres numéros",
               "Collecteur",
               "DAYCOLLECTED",
               "ENDOFPERIODDAY",
               "ENDOFPERIODMONTH",
               "ENDOFPERIODYEAR",
               "Espèce",
               "Famille",
               "GenBank",
               "Genre",
               "LatitudeDecimale",
               "Localité",
               "LongitudeDecimale",
               "MONTHCOLLECTED",
               "Nb.",
               "Numéro scientifique GBIF",
               "Ordre",
               "Parties",
               "Pays",
               "PrecisionGEO",
               "Province",
               "Remarques",
               "SAISON",
               "Sexe",
               "Sous espèce",
               "Station",
               "YEARCOLLECTED"
             ]
    end

    test "import invalid file from path" do
      {:ok, collection} = Collection.create(%{name: "Test Collection"})

      {:error, error} =
        ImportFile.create_from_path(
          collection,
          "test/support/fixtures/files/no-recent-events.jpeg"
        )

      assert Enum.at(error.errors, 0).message
             |> String.contains?("path is invalid, duet to error")
    end

    test "import invalid path" do
      {:ok, collection} = Collection.create(%{name: "Test Collection"})

      {:error, error} =
        ImportFile.create_from_path(
          collection,
          "test/bla"
        )

      assert Enum.at(error.errors, 0).message
             |> String.contains?("error open file: test/bla, No such file or directory")
    end
  end
end
