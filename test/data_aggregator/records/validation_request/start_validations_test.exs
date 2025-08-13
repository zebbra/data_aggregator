defmodule DataAggregator.StartValidationsTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures
  import DataAggregator.SwissSpeciesFixtures

  alias DataAggregator.AccountsFixtures
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler

  describe "start validations action test" do
    setup do
      stub_with(Gbif.RestAPI, Gbif.RestAPIStub)

      swiss_species_fixture(%{
        taxon_id_ch: 10_001,
        usage_key: 9368,
        scientific_name: "Scientific Name 1",
        accepted_name: "Accepted Name 1",
        rank: "species",
        center: :infofauna
      })

      swiss_species_fixture(%{
        taxon_id_ch: 10_002,
        usage_key: 5_497_504,
        scientific_name: "Scientific Name 1",
        accepted_name: "Accepted Name 1",
        rank: "species",
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
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: 9368
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: 9368
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: 9368
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          tax_taxon_id: 5_497_504
        })

      record5 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "My Kingdom"
        })

      encoded_record_fixture(%{record: record1})
      encoded_record_fixture(%{record: record2})
      encoded_record_fixture(%{record: record3})
      encoded_record_fixture(%{record: record4})
      encoded_record_fixture(%{record: record5})

      [
        collection: collection,
        actor: actor
      ]
    end

    test "start_validations creates a validation request for each center", %{
      collection: collection,
      actor: actor
    } do
      Oban.Testing.with_testing_mode(:manual, fn ->
        {:ok, result} =
          Collection.start_validations(collection, actor: actor, tenant: collection)

        # after all validation requests are created and enqueued, the collection state is set to :validating
        {:ok, collection} = Collection.get_by_id(collection.id)
        assert collection.state == :validating

        assert_lists_equal(result,
          infofauna: 3,
          vogelwarte: 0,
          infoflora: 0,
          swissbryophytes: 0,
          swisslichens: 0,
          swissfungi: 1
        )

        {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

        Enum.each(validation_requests, fn vr ->
          assert vr != nil
          assert vr.attachment_id == nil
          assert vr.state == :queued
        end)
      end)

      jobs = all_enqueued()
      assert length(jobs) == 2

      Enum.each(jobs, &perform_job(ValidationRequestHandler, &1.args, []))

      # after all validation requests are run, the collection state is set to :idle
      {:ok, collection} = Collection.get_by_id(collection.id)
      assert collection.state == :idle
      {:ok, validation_requests} = Ash.read(ValidationRequest, tenant: collection)

      assert length(validation_requests) == 2

      Enum.each(validation_requests, fn vr ->
        assert vr != nil
        assert vr.attachment_id != nil
        assert vr.state == :done
      end)

      infofauna_request = Enum.find(validation_requests, &(&1.center == :infofauna))
      swissfungi_request = Enum.find(validation_requests, &(&1.center == :swissfungi))

      assert infofauna_request.total_rows_count == 3
      assert infofauna_request.processed_rows_count == 3
      assert swissfungi_request.total_rows_count == 1
      assert swissfungi_request.processed_rows_count == 1
    end
  end
end
