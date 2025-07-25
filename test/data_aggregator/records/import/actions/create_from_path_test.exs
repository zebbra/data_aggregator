defmodule DataAggregator.Records.Import.Actions.CreateFromPathTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias Ash.Error.Invalid
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @valid_path "test/support/fixtures/files/museum-dataset-import-example.csv"
  @invalid_path "test/support/fixtures/files/no-recent-events.jpeg"

  describe "DataAggregator.Records.Import.create_from_path/2" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      collection =
        Collection.create!(%{
          type: :zoology,
          name: "Test Collection",
          owner: "Max Powers",
          grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
        })

      [collection: collection]
    end

    test "with valid file", %{collection: collection} do
      {:ok, import} = Import.create_from_path(collection, @valid_path, tenant: collection)

      assert import.state == :pending
      assert import.rows_count == 891

      columns = Enum.map(import.columns, &{&1.name, &1.type})

      assert columns == [
               {"Scientific Name", :string},
               {"Numéro scientifique GBIF", :string},
               {"Ordre", :string},
               {"Famille", :string},
               {"Genre", :string},
               {"Espèce", :string},
               {"Sous espèce", :string},
               {"Auteur et date ssp", :string},
               {"Sexe", :string},
               {"Age", :string},
               {"Parties", :string},
               {"Autres numéros", :string},
               {"Pays", :string},
               {"Province", :string},
               {"Localité", :string},
               {"Station", :string},
               {"LongitudeDecimale", :string},
               {"LatitudeDecimale", :string},
               {"PrecisionGEO", :string},
               {"Remarques", :string},
               {"DAYCOLLECTED", :string},
               {"MONTHCOLLECTED", :string},
               {"YEARCOLLECTED", :string},
               {"ENDOFPERIODDAY", :string},
               {"ENDOFPERIODMONTH", :string},
               {"ENDOFPERIODYEAR", :string},
               {"Collecteur", :string}
             ]
    end

    test "with custom filename", %{collection: collection} do
      {:ok, import} =
        Import.create_from_path(collection, @valid_path, %{filename: "custom.csv"}, tenant: collection)

      assert import.attachment_filename == "custom.csv"
    end

    test "with invalid file", %{collection: collection} do
      {:error, error} = Import.create_from_path(collection, @invalid_path)

      assert_invalid_path(
        error,
        ~r/Could not detect CSV delimiter/
      )
    end

    test "with invalid field format prints nicely formatted error", %{collection: collection} do
      {:error, error} =
        Import.create_from_path(
          collection,
          "test/support/fixtures/files/invalid_field_format.txt"
        )

      assert_invalid_path(
        error,
        "Could not parse '02. M�r' as data type 'str' for field '_duplicated_0'. Please verify your data."
      )
    end

    test "with non-existing file", %{collection: collection} do
      path = "test/this-file-does-not-exist.csv"
      {:error, error} = Import.create_from_path(collection, path, tenant: collection)

      assert_invalid_path(
        error,
        ~r/no such file or directory/
      )
    end

    defp assert_invalid_path(error, message) when is_binary(message) do
      assert_has_error(
        error.changeset,
        Invalid,
        &(&1.field == :path && &1.message == message)
      )
    end

    defp assert_invalid_path(error, message) when is_struct(message, Regex) do
      assert_has_error(
        error.changeset,
        Invalid,
        &(&1.field == :path && String.match?(&1.message, message))
      )
    end
  end
end
