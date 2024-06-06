defmodule DataAggregator.Records.Import.Actions.UpdateMappingTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

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
          {cat.name, Enum.map(cat.dwc_attributes, & &1.attribute.name)}
        end)

      assert missing_attributes == [{:tax, [:scientific_name]}, {:mte, [:catalog_number]}]

      assert import.state == :pending

      assert columns == [
               {"Scientific Name", :string, nil},
               {"Numéro scientifique GBIF", :string, nil},
               {"Ordre", :string, nil},
               {"Famille", :string, nil},
               {"Genre", :string, nil},
               {"Espèce", :string, nil},
               {"Sous espèce", :string, nil},
               {"Auteur et date ssp", :string, nil},
               {"Sexe", :string, nil},
               {"Age", :string, "age"},
               {"Parties", :string, nil},
               {"Autres numéros", :string, nil},
               {"Pays", :string, nil},
               {"Province", :string, nil},
               {"Localité", :string, nil},
               {"Station", :string, nil},
               {"LongitudeDecimale", :float, nil},
               {"LatitudeDecimale", :float, nil},
               {"PrecisionGEO", :string, nil},
               {"Remarques", :string, nil},
               {"DAYCOLLECTED", :integer, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"YEARCOLLECTED", :integer, nil},
               {"ENDOFPERIODDAY", :integer, nil},
               {"ENDOFPERIODMONTH", :integer, nil},
               {"ENDOFPERIODYEAR", :integer, nil},
               {"Collecteur", :string, nil}
             ]

      mappings = [
        %{name: "Age", mapped_to: ""},
        %{name: "Collecteur", mapped_to: "coll"}
      ]

      {:ok, import} = Import.update_mapping(import, mappings)
      columns = Enum.map(import.columns, &{&1.name, &1.type, &1.mapped_to})

      assert columns == [
               {"Scientific Name", :string, nil},
               {"Numéro scientifique GBIF", :string, nil},
               {"Ordre", :string, nil},
               {"Famille", :string, nil},
               {"Genre", :string, nil},
               {"Espèce", :string, nil},
               {"Sous espèce", :string, nil},
               {"Auteur et date ssp", :string, nil},
               {"Sexe", :string, nil},
               {"Age", :string, nil},
               {"Parties", :string, nil},
               {"Autres numéros", :string, nil},
               {"Pays", :string, nil},
               {"Province", :string, nil},
               {"Localité", :string, nil},
               {"Station", :string, nil},
               {"LongitudeDecimale", :float, nil},
               {"LatitudeDecimale", :float, nil},
               {"PrecisionGEO", :string, nil},
               {"Remarques", :string, nil},
               {"DAYCOLLECTED", :integer, nil},
               {"MONTHCOLLECTED", :integer, nil},
               {"YEARCOLLECTED", :integer, nil},
               {"ENDOFPERIODDAY", :integer, nil},
               {"ENDOFPERIODMONTH", :integer, nil},
               {"ENDOFPERIODYEAR", :integer, nil},
               {"Collecteur", :string, "coll"}
             ]
    end
  end
end
