defmodule DataAggregator.SwissSpeciesRegistryImporterTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry
  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistryImporter

  doctest SwissSpeciesRegistryImporter, import: true

  @fixtures_path "test/support/fixtures/files"

  describe "import_from_json/1" do
    test "imports accepted species entries correctly" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test.json")

      assert :ok = SwissSpeciesRegistryImporter.import_from_json(path)

      # Verify the first accepted species was imported
      {:ok, entry} =
        SwissSpeciesRegistry.get_by_scientific_name("Parasyrisca vinosa (Simon, 1878)")

      assert entry.scientific_name == "Parasyrisca vinosa (Simon, 1878)"
      assert entry.taxon_id_ch == "10000"
      assert entry.accepted_name_usage == "Parasyrisca vinosa (Simon, 1878)"
      assert entry.center == :infofauna
      assert entry.rank == "species"
      assert entry.status == "accepted"
    end

    test "imports multiple accepted species entries" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test.json")

      assert :ok = SwissSpeciesRegistryImporter.import_from_json(path)

      # Verify multiple entries were imported
      {:ok, entry1} =
        SwissSpeciesRegistry.get_by_scientific_name("Parasyrisca vinosa (Simon, 1878)")

      {:ok, entry2} =
        SwissSpeciesRegistry.get_by_scientific_name("Echemus angustifrons (Westring, 1861)")

      {:ok, entry3} = SwissSpeciesRegistry.get_by_scientific_name("Gnaphosa alpica Simon, 1878")

      assert entry1.taxon_id_ch == "10000"
      assert entry2.taxon_id_ch == "10001"
      assert entry3.taxon_id_ch == "10002"

      assert entry1.center == :infofauna
      assert entry2.center == :infofauna
      assert entry3.center == :infofauna
    end

    test "imports synonym entries with accepted name usage" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test.json")

      assert :ok = SwissSpeciesRegistryImporter.import_from_json(path)

      # Verify the synonym entry was imported correctly
      {:ok, entry} =
        SwissSpeciesRegistry.get_by_scientific_name("Haplodrassus dalmatensis pictus (Thorell, 1875)")

      assert entry.scientific_name == "Haplodrassus dalmatensis pictus (Thorell, 1875)"
      assert entry.taxon_id_ch == "10076"
      assert entry.accepted_name_usage == "Haplodrassus dalmatensis (L. Koch, 1866)"
      assert entry.center == :infofauna
      assert entry.rank == "subspecies"
      assert entry.status == "synonym"
    end

    test "imports entries from nism center and maps to swissbryophytes" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test.json")

      assert :ok = SwissSpeciesRegistryImporter.import_from_json(path)

      {:ok, entry} = SwissSpeciesRegistry.get_by_scientific_name("Bryum argenteum Hedw.")

      assert entry.scientific_name == "Bryum argenteum Hedw."
      assert entry.taxon_id_ch == "50001"
      assert entry.center == :swissbryophytes
      assert entry.rank == "species"
      assert entry.status == "accepted"
    end

    test "imports entries from swissfungi center" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test.json")

      assert :ok = SwissSpeciesRegistryImporter.import_from_json(path)

      {:ok, entry} = SwissSpeciesRegistry.get_by_scientific_name("Agaricus campestris L.")

      assert entry.scientific_name == "Agaricus campestris L."
      assert entry.taxon_id_ch == "60001"
      assert entry.center == :swissfungi
      assert entry.rank == "species"
      assert entry.status == "accepted"
    end

    test "logs warning for entries with empty results" do
      # Create a temporary JSON file with empty results
      tmp_path = Path.join(System.tmp_dir!(), "empty_results_test.json")

      json_content =
        Jason.encode!(%{
          "Unknown species" => %{"result" => []}
        })

      File.write!(tmp_path, json_content)

      {result, logs} =
        with_log(fn ->
          SwissSpeciesRegistryImporter.import_from_json(tmp_path)
        end)

      assert result == :ok
      assert logs =~ "No results found for Unknown species"

      File.rm!(tmp_path)
    end

    test "logs error for entries with duplicate results" do
      # Create a temporary JSON file with duplicate results
      tmp_path = Path.join(System.tmp_dir!(), "duplicate_results_test.json")

      json_content =
        Jason.encode!(%{
          "Duplicate species" => %{
            "result" => [
              %{
                "id" => "infofauna:1",
                "usage" => %{
                  "label" => "Duplicate species 1",
                  "status" => "accepted",
                  "name" => %{"rank" => "species"}
                }
              },
              %{
                "id" => "infofauna:2",
                "usage" => %{
                  "label" => "Duplicate species 2",
                  "status" => "accepted",
                  "name" => %{"rank" => "species"}
                }
              }
            ]
          }
        })

      File.write!(tmp_path, json_content)

      {result, logs} =
        with_log(fn ->
          SwissSpeciesRegistryImporter.import_from_json(tmp_path)
        end)

      assert result == :ok
      assert logs =~ "Duplicate entries found for Duplicate species"

      File.rm!(tmp_path)
    end
  end
end
