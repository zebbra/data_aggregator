defmodule DataAggregator.StartValidationsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.SwissSpeciesRegistryFixtures

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler

  describe "start validations action test" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      swiss_species_registry_fixture(%{
        scientific_name: "Scientific Name 1",
        center: :infofauna
      })

      swiss_species_registry_fixture(%{
        scientific_name: "Scientific Name 2",
        center: :swissfungi
      })

      actor =
        AccountsFixtures.user_fixture(%{
          email: "john.doe@example.com",
          password: "secret42",
          roles: ["admin", "collection_administrator", "data_digitizer"]
        })

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      record1 =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "CH",
          oth_swiss_species_registered: true
        })

      record2 =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "ch",
          oth_swiss_species_registered: true
        })

      record3 =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "CH",
          oth_swiss_species_registered: true
        })

      record4 =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 2",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "5_497_504",
          loc_country_code: "CH",
          oth_swiss_species_registered: true
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom",
          loc_country_code: "CH",
          oth_swiss_species_registered: true
        })

      record6 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom",
          loc_country_code: "FR",
          oth_swiss_species_registered: false
        })

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})
      encoded_record_fixture(%{record: record6})

      [
        collection: collection,
        actor: actor
      ]
    end

    test "start_validations creates a validation request for each center", %{
      collection: collection,
      actor: actor
    } do
      assert_start_validations_result_equal(collection, actor,
        infofauna: 3,
        vogelwarte: 0,
        infoflora: 0,
        swissbryophytes: 0,
        swisslichens: 0,
        swissfungi: 1
      )

      jobs = all_enqueued()
      assert length(jobs) == 2

      Enum.each(jobs, &perform_job(ValidationRequestHandler, &1.args, []))

      # after all validation requests are run, the collection state is set to :idle
      {:ok, collection} = Collection.get_by_id(collection.id)
      assert collection.state == :idle
      {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

      Enum.each(validation_requests, fn vr ->
        assert vr
        assert vr.attachment_id
        assert vr.state == :done
      end)

      infofauna_request = Enum.find(validation_requests, &(&1.center == :infofauna))
      swissfungi_request = Enum.find(validation_requests, &(&1.center == :swissfungi))

      assert infofauna_request.total_rows_count == 3
      assert infofauna_request.processed_rows_count == 3
      assert swissfungi_request.total_rows_count == 1
      assert swissfungi_request.processed_rows_count == 1
    end

    test "start_validations does not create validation for oth_swiss_species_registered false or oth_basis_of_record FossilSpecimen",
         %{
           collection: collection,
           actor: actor
         } do
      assert_start_validations_result_equal(collection, actor,
        infofauna: 3,
        vogelwarte: 0,
        infoflora: 0,
        swissbryophytes: 0,
        swisslichens: 0,
        swissfungi: 1
      )

      # add a record that will be included
      record =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "CH",
          oth_swiss_species_registered: true
        })

      encoded_record_fixture(%{record: record})

      assert_start_validations_result_equal(collection, actor,
        infofauna: 4,
        vogelwarte: 0,
        infoflora: 0,
        swissbryophytes: 0,
        swisslichens: 0,
        swissfungi: 1
      )

      # add a record that will be excluded because oth_swiss_species_registered is false

      record_excluded_1 =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "CH",
          oth_swiss_species_registered: false
        })

      encoded_record_fixture(%{record: record_excluded_1})

      assert_start_validations_result_equal(collection, actor,
        infofauna: 4,
        vogelwarte: 0,
        infoflora: 0,
        swissbryophytes: 0,
        swisslichens: 0,
        swissfungi: 1
      )

      # add a record that will be excluded because oth_basis_of_record is FossilSpecimen
      record_excluded_2 =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "CH",
          oth_swiss_species_registered: true,
          oth_basis_of_record: "FossilSpecimen"
        })

      encoded_record_fixture(%{record: record_excluded_2})

      assert_start_validations_result_equal(collection, actor,
        infofauna: 4,
        vogelwarte: 0,
        infoflora: 0,
        swissbryophytes: 0,
        swisslichens: 0,
        swissfungi: 1
      )
    end
  end

  defp assert_start_validations_result_equal(collection, actor, expected) do
    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, result} =
        Collection.start_validations(collection, actor: actor, tenant: collection)

      {:ok, collection} = Collection.get_by_id(collection.id)

      assert_lists_equal(result, expected)

      {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

      Enum.each(validation_requests, fn vr ->
        assert vr
        assert vr.attachment_id == nil
        assert vr.state == :queued
      end)
    end)
  end
end
