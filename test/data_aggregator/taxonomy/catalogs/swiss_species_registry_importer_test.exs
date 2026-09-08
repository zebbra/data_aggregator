defmodule DataAggregator.SwissSpeciesRegistryImporterTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistry
  alias DataAggregator.Taxonomy.Catalogs.SwissSpeciesRegistryImporter

  doctest SwissSpeciesRegistryImporter, import: true

  @fixtures_path "test/support/fixtures/files"

  describe "import_from_json/1" do
    test "import real data correctly" do
      assert %{bulk_create_errors: 0, created: 47_682, duplicate_entries: 0, no_results: 0} =
               SwissSpeciesRegistryImporter.import_from_json("priv/initialize/catalogs/swiss_species_registry.ndjson")
    end

    test "imports correct values" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test.ndjson")

      assert %{bulk_create_errors: 0, created: 6, duplicate_entries: 0, no_results: 0} =
               SwissSpeciesRegistryImporter.import_from_json(path)

      # Verify the first accepted species was imported
      {:ok, entry} =
        SwissSpeciesRegistry.get_by_scientific_name("Parasyrisca vinosa (Simon, 1878)")

      {:ok, synonym_entry} =
        SwissSpeciesRegistry.get_by_scientific_name("Haplodrassus dalmatensis pictus (Thorell, 1875)")

      {:ok, bryophyte_entry} =
        SwissSpeciesRegistry.get_by_scientific_name("Bryum argenteum Hedw.")

      assert entry.scientific_name == "Parasyrisca vinosa (Simon, 1878)"
      assert entry.taxon_id_ch == "10000"
      assert entry.accepted_name_usage == "Parasyrisca vinosa (Simon, 1878)"
      assert entry.center == :infofauna
      assert entry.rank == "species"
      assert entry.status == "accepted"

      assert synonym_entry.scientific_name == "Haplodrassus dalmatensis pictus (Thorell, 1875)"
      assert synonym_entry.taxon_id_ch == "10076"
      assert synonym_entry.accepted_name_usage == "Haplodrassus dalmatensis (L. Koch, 1866)"
      assert synonym_entry.center == :infofauna
      assert synonym_entry.rank == "subspecies"
      assert synonym_entry.status == "synonym"

      assert bryophyte_entry.scientific_name == "Bryum argenteum Hedw."
      assert bryophyte_entry.taxon_id_ch == "50001"
      assert bryophyte_entry.center == :swissbryophytes
      assert bryophyte_entry.rank == "species"
      assert bryophyte_entry.status == "accepted"
    end

    test "imports entries with no results and duplicate results correctly" do
      path = Path.join(@fixtures_path, "swiss_species_registry_test_with_errors.ndjson")

      # 1 no results, 1 duplicate results, 1 scientific_name missing (bulk create fail), 5 valid
      assert %{
               bulk_create_errors: 1,
               created: 5,
               duplicate_entries: 1,
               no_results: 1
             } = SwissSpeciesRegistryImporter.import_from_json(path)

      # Verify that the valid entries were imported
      {:ok, entry} =
        SwissSpeciesRegistry.get_by_scientific_name("Bryum argenteum Hedw.")

      assert entry.scientific_name == "Bryum argenteum Hedw."
      assert entry.taxon_id_ch == "50001"
      assert entry.center == :swissbryophytes
      assert entry.rank == "species"
      assert entry.status == "accepted"
    end
  end
end
