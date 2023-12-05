defmodule DataAggregator.Records.ImportTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  setup do
    {:ok, collection} =
      Collection.create(%{
        name: "Test Collection",
        owner: "Max Powers",
        reviewer: :swiss_bryophytes
      })

    %{collection: collection}
  end

  describe "action: create_from_path" do
    test "with valid file", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      {:ok, import} = Import.create_from_path(collection, path)

      assert import.state == :pending

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

    test "with custom filename", %{collection: collection} do
      path = "test/support/fixtures/files/museum-dataset-import-example.csv"
      {:ok, import} = Import.create_from_path(collection, path, %{filename: "custom.csv"})

      assert import.attachment_filename == "custom.csv"
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
