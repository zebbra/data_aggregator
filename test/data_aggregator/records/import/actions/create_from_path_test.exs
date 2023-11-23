defmodule DataAggregator.Records.Import.Actions.CreateFromPathTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @valid_path "test/support/fixtures/files/museum-dataset-import-example.csv"
  @invalid_path "test/support/fixtures/files/no-recent-events.jpeg"

  describe "DataAggregator.Records.Import.create_from_path/2" do
    setup do
      collection = Collection.create!(%{name: "Test Collection", owner: "Max Powers"})
      [collection: collection]
    end

    test "with valid file", %{collection: collection} do
      {:ok, import} = Import.create_from_path(collection, @valid_path)

      assert import.state == :pending
      assert import.rows_count == 891

      columns = Enum.map(import.columns, &{&1.name, &1.type})

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
      {:ok, import} = Import.create_from_path(collection, @valid_path, %{filename: "custom.csv"})

      assert import.attachment_filename == "custom.csv"
    end

    test "with invalid file", %{collection: collection} do
      {:error, error} = Import.create_from_path(collection, @invalid_path)

      assert_invalid_path(
        error,
        ~r/Could not detect CSV delimiter/
      )
    end

    test "with non-existing file", %{collection: collection} do
      path = "test/this-file-does-not-exist.csv"
      {:error, error} = Import.create_from_path(collection, path)

      assert_invalid_path(
        error,
        ~r/no such file or directory/
      )
    end

    defp assert_invalid_path(error, message) when is_binary(message) do
      assert_has_error(
        error.changeset,
        Ash.Error.Invalid,
        &(&1.field == :path && &1.message == message)
      )
    end

    defp assert_invalid_path(error, message) when is_struct(message, Regex) do
      assert_has_error(
        error.changeset,
        Ash.Error.Invalid,
        &(&1.field == :path && String.match?(&1.message, message))
      )
    end
  end
end
