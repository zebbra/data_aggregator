defmodule DataAggregator.Records.Import.Actions.UpdateMappingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  setup do
    collection =
      Collection.create!(%{
        name: "Test Collection",
        owner: "Max Powers",
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      })

    [collection: collection]
  end

  setup %{collection: collection, path: path} do
    import = Import.create_from_path!(collection, path)
    [import: import]
  end

  describe "DataAggregator.Records.update_mapping/1" do
    @tag path: "test/support/fixtures/files/museum-dataset-import-example.csv"
    test "with valid file", %{import: import} do
      mappings = [
        %{"name" => "Age", "mapped_to" => "age"},
        %{"name" => "Collecteur", "mapped_to" => ""}
      ]

      {:ok, import} = Import.update_mapping(import, mappings)
      columns = Enum.map(import.columns, &{&1.name, &1.type, &1.mapped_to})

      missing_attributes =
        Enum.map(import.missing_mappings, fn cat ->
          {cat.name, Enum.map(cat.attributes, & &1.name)}
        end)

      assert missing_attributes == [{:tax, [:scientific_name]}, {:mte, [:catalog_number]}]

      assert import.state == :pending

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
      columns = Enum.map(import.columns, &{&1.name, &1.type, &1.mapped_to})

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
end
