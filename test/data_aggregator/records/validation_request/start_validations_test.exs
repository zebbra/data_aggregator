defmodule DataAggregator.StartValidationsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.SwissSpeciesRegistryFixtures
  import Swoosh.TestAssertions

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

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

    test "start_validations creates a validation request for every center", %{
      collection: collection,
      actor: actor
    } do
      assert_start_validations_creates_all_centers(collection, actor)

      jobs = all_enqueued()
      assert length(jobs) == length(InfospeciesCenters.get_center_names())

      Enum.each(jobs, &perform_job(ValidationRequestHandler, &1.args, []))

      # after all validation requests are run, the collection state is set to :idle
      {:ok, collection} = Collection.get_by_id(collection.id)
      assert collection.state == :idle
      {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

      assert length(validation_requests) == length(InfospeciesCenters.get_center_names())

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

      # centers with no matching records still produce a VR, but it is empty
      empty_centers =
        InfospeciesCenters.get_center_names() -- [:infofauna, :swissfungi]

      Enum.each(empty_centers, fn center ->
        vr = Enum.find(validation_requests, &(&1.center == center))
        assert vr.total_rows_count == 0
        assert vr.processed_rows_count == 0
        assert vr.sent_for_validation_count == 0
      end)
    end

    test "empty validation requests do not notify infospecies centers", %{
      collection: collection,
      actor: actor
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, _result} =
          Collection.start_validations(collection, actor: actor, tenant: collection)

        Enum.each(all_enqueued(), &perform_job(ValidationRequestHandler, &1.args, []))
      end)

      # Only the two centers that have matching records should receive an email.
      Enum.each([:infofauna, :swissfungi], fn center ->
        {:ok, to_mails} = InfospeciesCenters.get_center_emails(center)
        [first_email | _] = to_mails

        assert_email_sent(fn email ->
          Enum.any?(email.to, fn {_, addr} -> addr == first_email end)
        end)
      end)

      # Every other center has a 0-row VR and must not trigger a notification.
      refute_email_sent()
    end

    test "records with oth_swiss_species_registered false or oth_basis_of_record FossilSpecimen are excluded from counts",
         %{
           collection: collection,
           actor: actor
         } do
      # add a record that will be included
      record_included =
        record_fixture(%{
          tax_scientific_name: "Scientific Name 1",
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: "9368",
          loc_country_code: "CH",
          oth_swiss_species_registered: true
        })

      encoded_record_fixture(%{record: record_included})

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

      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, _result} =
          Collection.start_validations(collection, actor: actor, tenant: collection)

        Enum.each(all_enqueued(), &perform_job(ValidationRequestHandler, &1.args, []))
      end)

      {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

      infofauna_request = Enum.find(validation_requests, &(&1.center == :infofauna))
      swissfungi_request = Enum.find(validation_requests, &(&1.center == :swissfungi))

      # 3 original + 1 newly added "Scientific Name 1" record; the 2 excluded records do not count
      assert infofauna_request.total_rows_count == 4
      assert swissfungi_request.total_rows_count == 1
    end
  end

  defp assert_start_validations_creates_all_centers(collection, actor) do
    Oban.Testing.with_testing_mode(:manual, fn ->
      {:ok, result} =
        Collection.start_validations(collection, actor: actor, tenant: collection)

      assert_lists_equal(result, InfospeciesCenters.get_center_names())

      {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

      assert length(validation_requests) == length(InfospeciesCenters.get_center_names())

      Enum.each(validation_requests, fn vr ->
        assert vr
        assert vr.attachment_id == nil
        assert vr.state == :queued
      end)
    end)
  end
end
