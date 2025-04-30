defmodule DataAggregator.WorkflowTest do
  @moduledoc false

  use DataAggregator.DataCase, async: false
  use Mimic

  import DataAggregator.AccountsFixtures, only: [user_fixture: 0]
  import DataAggregator.EncodingFixtures, only: [expect_correct_swiss_species_api_call: 0]

  alias DataAggregator.Gbif
  alias DataAggregator.Opencage
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Import.Workers.Importer
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.Workers.Publisher
  alias DataAggregator.Records.Record
  alias DataAggregator.Records.Record.Workers.Encoder
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Records.ValidationRequest.Workers.ValidationRequestHandler
  alias DataAggregator.Taxonomy.Catalog

  require Ash.Query

  @catalog_versions length(Catalog.get_catalogs()) - 2

  @mapping [
    %{name: "basisOfRecord", mapped_to: "oth_basis_of_record"},
    %{name: "catalogNumber", mapped_to: "mte_catalog_number"},
    %{name: "verbatimLocality", mapped_to: "loc_verbatim_locality"},
    %{name: "verbatimElevation", mapped_to: "loc_verbatim_elevation"},
    %{name: "locality", mapped_to: "loc_locality"},
    %{name: "countryCode", mapped_to: "loc_country_code"},
    %{name: "higherGeography", mapped_to: "loc_higher_geography"},
    %{name: "country", mapped_to: "loc_country"},
    %{name: "stateProvince", mapped_to: "loc_state_province"},
    %{name: "locationRemarks", mapped_to: "loc_location_remarks"},
    %{name: "verbatimLabel", mapped_to: "mte_verbatim_label"},
    %{name: "materialEntityRemarks", mapped_to: "mte_material_entity_remarks"},
    %{name: "typeStatus", mapped_to: "idf_type_status"},
    %{name: "verbatimEventDate", mapped_to: "eve_verbatim_event_date"},
    %{name: "day", mapped_to: "eve_day"},
    %{name: "endOfPeriodDay", mapped_to: "eve_end_of_period_day"},
    %{name: "month", mapped_to: "eve_month"},
    %{name: "endOfPeriodMonth", mapped_to: "eve_end_of_period_month"},
    %{name: "year", mapped_to: "eve_year"},
    %{name: "endOfPeriodYear", mapped_to: "eve_end_of_period_year"},
    %{name: "eventDate", mapped_to: "eve_event_date"},
    %{name: "eventRemarks", mapped_to: "eve_event_remarks"},
    %{name: "lifeStage", mapped_to: "mte_life_stage"},
    %{name: "organismQuantityType", mapped_to: "mte_organism_quantity_type"},
    %{name: "recordedBy", mapped_to: "mte_recorded_by"},
    %{name: "kingdom", mapped_to: "tax_kingdom"},
    %{name: "verbatimIdentification", mapped_to: "idf_verbatim_identification"},
    %{name: "genus", mapped_to: "tax_genus"},
    %{name: "specificEpithet", mapped_to: "tax_specific_epithet"},
    %{name: "scientificNameAuthorship", mapped_to: "tax_scientific_name_authorship"},
    %{name: "taxonRank", mapped_to: "tax_taxon_rank"},
    %{name: "scientificName", mapped_to: "tax_scientific_name"},
    %{name: "identificationRemarks", mapped_to: "idf_identification_remarks"},
    %{name: "preservationDateBegin", mapped_to: "pvn_preservation_date_begin"},
    %{name: "verbatimDepth", mapped_to: "loc_verbatim_depth"},
    %{name: "dateAvailable", mapped_to: "oth_date_available"}
  ]

  @publication_states [
    :not_published,
    :publishing,
    :in_publication,
    :published,
    :publication_failed,
    :stale
  ]

  @validation_state_lookup %{
    :not_published => :not_validated,
    :publishing => :validating,
    :in_publication => :in_validation,
    :published => :validated,
    :publication_failed => :validation_failed,
    :stale => :stale
  }

  setup do
    stub_with(Gbif.RestAPI, Gbif.RestAPIStub)
    stub_with(Opencage.RestAPI, Opencage.RestAPIStub)

    collection =
      Collection.create!(%{
        type: :zoology,
        owner: "John Doe",
        grscicoll_reference: "322ce107-3156-4420-8a2b-7f17efeaa472"
      })

    actor = user_fixture()

    [collection: collection, actor: actor]
  end

  test "it creates the collection (sanity check)", %{collection: collection} do
    assert collection.name == "Herbarium - Universität Zürich"
    assert collection.owner == "John Doe"
    assert collection.grscicoll_reference == "322ce107-3156-4420-8a2b-7f17efeaa472"
  end

  describe "Importer.perform/1" do
    setup %{collection: collection, actor: actor} do
      path = "test/support/fixtures/files/workflow.csv"

      import =
        collection
        |> Import.create_from_path!(path, tenant: collection)
        |> Import.update_mapping!(@mapping)

      {:ok, import} =
        perform_job(Importer, %{
          id: import.id,
          collection_id: import.collection_id,
          user_id: actor.id
        })

      [import: import, actor: actor]
    end

    test "import workflow performs as expected", %{
      import: import,
      actor: actor,
      collection: tenant
    } do
      assert import.state == :imported
      import = Ash.load!(import, [:records_count])
      assert import.records_count == 6

      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{state: :imported, publication_status: :not_published, validation_status: :not_validated}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)
      # record create -> import versions for each record have been created
      assert_create_import_versions(records, actor)
      # no encoded_records versions should have been created
      assert_no_encode_verions(tenant)

      # update the states of the records so we can test the workflow
      update_states(records)

      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{state: :imported, publication_status: :publishing, validation_status: :validating},
        %{
          state: :imported,
          publication_status: :in_publication,
          validation_status: :in_validation
        },
        %{state: :imported, publication_status: :published, validation_status: :validated},
        %{
          state: :imported,
          publication_status: :publication_failed,
          validation_status: :validation_failed
        },
        %{state: :imported, publication_status: :stale, validation_status: :stale}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)
      # assert that we removed the update versions
      assert_create_import_versions(records, actor)
      # no encoded_records versions should have been created
      assert_no_encode_verions(tenant)

      import = Ash.update!(import, %{state: :pending})
      assert import.state == :pending

      perform_job(Importer, %{
        id: import.id,
        collection_id: import.collection_id,
        user_id: actor.id
      })

      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{state: :imported, publication_status: :stale, validation_status: :stale},
        %{state: :imported, publication_status: :stale, validation_status: :stale},
        %{state: :imported, publication_status: :stale, validation_status: :stale},
        %{state: :imported, publication_status: :stale, validation_status: :stale},
        %{state: :imported, publication_status: :stale, validation_status: :stale}
      ]

      assert_states_equal(expected, records)
      # record create -> import versions for each record have been created a second time
      assert_create_import_versions(records, actor, 2)
      # no encoded_records versions should have been created
      assert_no_encode_verions(tenant)
    end
  end

  describe "Encoder.perform/1" do
    setup %{collection: collection, actor: actor} do
      path = "test/support/fixtures/files/workflow.csv"

      import =
        collection
        |> Import.create_from_path!(path, tenant: collection)
        |> Import.update_mapping!(@mapping)

      {:ok, import} =
        perform_job(Importer, %{
          id: import.id,
          collection_id: import.collection_id,
          user_id: actor.id
        })

      [import: import, actor: actor]
    end

    test "encoding workflow performs as expected", %{
      import: import,
      actor: actor,
      collection: tenant
    } do
      assert import.state == :imported
      import = Ash.load!(import, [:records_count])
      assert import.records_count == 6

      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{
          state: :imported,
          publication_status: :not_published,
          validation_status: :not_validated
        },
        %{state: :imported, publication_status: :not_published, validation_status: :not_validated}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)
      # record create -> import versions for each record have been created
      assert_create_import_versions(records, actor)
      # no encoded_records versions should have been created
      assert_no_encode_verions(tenant)

      encode_records(records, actor)
      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated}
      ]

      # assert we detected all changes
      assert_changes(records)
      # assert that the records are in the correct state
      assert_states_equal(expected, records)
      # no new records versions should have been created
      assert_create_import_versions(records, actor)
      # encoded_record versions for each record have been created
      assert_encode_versions(actor, tenant)
    end
  end

  describe "Publisher.perform/1 publication" do
    setup %{collection: collection, actor: actor} do
      path = "test/support/fixtures/files/workflow.csv"

      import =
        collection
        |> Import.create_from_path!(path, tenant: collection)
        |> Import.update_mapping!(@mapping)

      perform_job(Importer, %{
        id: import.id,
        collection_id: import.collection_id,
        user_id: actor.id
      })

      encode_records(Ash.read!(Record, load: [:paper_trail_versions], tenant: collection), actor)
      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: collection)

      query = %{
        collection: %{id: %{eq: collection.id}},
        tax_kingdom: %{is_nil: false}
      }

      publication =
        Publication.create!(
          %{
            name: "publication-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
            collection: collection,
            records_query: query
          },
          tenant: collection
        )

      [publication: publication, actor: actor, records: records]
    end

    test "publishing workflow performs as expected", %{
      publication: publication,
      records: records,
      actor: actor,
      collection: tenant
    } do
      # Sanity check
      assert length(records) == 6

      expected = [
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)
      # no new records versions should have been created
      assert_create_import_versions(records, actor)
      # encoded_record versions for each record have been created
      assert_encode_versions(actor, tenant)

      perform_job(Publisher, %{
        id: publication.id,
        collection_id: publication.collection_id,
        user_id: actor.id
      })

      publication = Publication.get_by_id!(publication.id, tenant: tenant)

      assert publication.state == :done
      assert publication.published_count == 6

      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{state: :encoded, publication_status: :published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :published, validation_status: :not_validated}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)

      versions =
        records
        |> Enum.map(& &1.paper_trail_versions)
        |> List.flatten()
        |> Enum.map(
          &Map.take(&1, [
            :version_action_name,
            :version_action_type,
            :user_id
          ])
        )

      # import, publication_updated (3x -> publishing, in_publication, published)
      expected_length = 6 * 4
      assert length(versions) == expected_length

      # Ensure all strategies set the user_id correctly
      for index <- 0..(expected_length - 1) do
        version = Enum.at(versions, index)
        assert version.user_id == actor.id
        assert version.version_action_name in [:import, :update_publication_status]
      end

      # no new records versions should have been created
      assert_encode_versions(actor, tenant)
    end
  end

  describe "ValidationRequestHandler.perform/1 validation request" do
    setup %{collection: collection, actor: actor} do
      path = "test/support/fixtures/files/workflow.csv"

      import =
        collection
        |> Import.create_from_path!(path, tenant: collection)
        |> Import.update_mapping!(@mapping)

      perform_job(Importer, %{
        id: import.id,
        collection_id: import.collection_id,
        user_id: actor.id
      })

      encode_records(Ash.read!(Record, load: [:paper_trail_versions], tenant: collection), actor)
      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: collection)

      # we cant set the relation from encoed_record to swiss_species as we
      # cant create a fixture for swiss_species as the module is copied
      # with mimic which leads to an error when trying to create a swiss_species
      # record
      query = %{
        collection: %{id: %{eq: collection.id}},
        tax_kingdom: %{is_nil: false}
        # encoded_record: %{swiss_species: %{center: %{eq: "infofauna"}}}
      }

      validation_request =
        ValidationRequest.create!(
          %{
            name: "validation-request-#{collection.name}-#{Uniq.UUID.uuid7(:slug)}",
            collection: collection,
            records_query: query,
            center: "infofauna"
          },
          tenant: collection
        )

      [validation_request: validation_request, actor: actor, records: records]
    end

    test "publishing workflow performs as expected", %{
      validation_request: validation_request,
      records: records,
      actor: actor,
      collection: tenant
    } do
      # Sanity check
      assert length(records) == 6

      expected = [
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated},
        %{state: :encoded, publication_status: :not_published, validation_status: :not_validated}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)
      # no new records versions should have been created
      assert_create_import_versions(records, actor)
      # encoded_record versions for each record have been created
      assert_encode_versions(actor, tenant)

      perform_job(ValidationRequestHandler, %{
        id: validation_request.id,
        collection_id: validation_request.collection_id,
        user_id: actor.id
      })

      validation_request = ValidationRequest.get_by_id!(validation_request.id, tenant: tenant)

      assert validation_request.state == :done
      assert validation_request.processed_rows_count == 6

      records = Ash.read!(Record, load: [:paper_trail_versions], tenant: tenant)
      assert length(records) == 6

      expected = [
        %{state: :encoded, publication_status: :not_published, validation_status: :in_validation},
        %{state: :encoded, publication_status: :not_published, validation_status: :in_validation},
        %{state: :encoded, publication_status: :not_published, validation_status: :in_validation},
        %{state: :encoded, publication_status: :not_published, validation_status: :in_validation},
        %{state: :encoded, publication_status: :not_published, validation_status: :in_validation},
        %{state: :encoded, publication_status: :not_published, validation_status: :in_validation}
      ]

      # assert that the records are in the correct state
      assert_states_equal(expected, records)

      versions =
        records
        |> Enum.map(& &1.paper_trail_versions)
        |> List.flatten()
        |> Enum.map(
          &Map.take(&1, [
            :version_action_name,
            :version_action_type,
            :user_id
          ])
        )

      # import, validation_updated (2x -> validating, and in_validation)
      expected_length = 6 * 3
      assert length(versions) == expected_length

      # Ensure all strategies set the user_id correctly
      for index <- 0..(expected_length - 1) do
        version = Enum.at(versions, index)
        assert version.user_id == actor.id
        assert version.version_action_name in [:import, :update_validation_status]
      end

      # no new records versions should have been created
      assert_encode_versions(actor, tenant)
    end
  end

  defp encode_records(records, actor) do
    Enum.each(records, fn record ->
      expect_correct_swiss_species_api_call()

      perform_job(Encoder, %{
        id: record.id,
        collection_id: record.collection_id,
        user_id: actor.id
      })
    end)
  end

  defp assert_states_equal(expected, records) do
    assert_lists_equal(
      expected,
      Enum.map(records, &Map.take(&1, [:state, :publication_status, :validation_status]))
    )
  end

  defp update_states(records) do
    Enum.with_index(@publication_states, fn state, index ->
      record = Enum.at(records, index)

      record
      |> Ash.update!(%{
        publication_status: state,
        validation_status: @validation_state_lookup[state]
      })
      |> Ash.load!(:paper_trail_versions)
      |> Map.get(:paper_trail_versions)
      |> Enum.filter(&(&1.version_action_type == :update))
      |> Enum.each(&Ash.destroy!(&1))
    end)
  end

  # record versions for x import iterations
  defp assert_create_import_versions(records, actor, iterations \\ 1) do
    versions =
      records
      |> Enum.map(&Ash.load!(&1, [:paper_trail_versions]))
      |> Enum.map(& &1.paper_trail_versions)
      |> List.flatten()
      |> Enum.map(
        &Map.take(&1, [
          :version_action_type,
          :version_action_name,
          :mte_catalog_number,
          :tax_scientific_name,
          :user_id
        ])
      )

    assert length(versions) == 6 * iterations

    expected = [
      %{
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        mte_catalog_number: "GBIFCH00993789",
        user_id: actor.id,
        version_action_name: :import,
        version_action_type: :create
      },
      %{
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        mte_catalog_number: "GBIFCH00993760",
        user_id: actor.id,
        version_action_name: :import,
        version_action_type: :create
      },
      %{
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        mte_catalog_number: "GBIFCH00993778",
        user_id: actor.id,
        version_action_name: :import,
        version_action_type: :create
      },
      %{
        tax_scientific_name: "Aphaenogaster subterranea (Latreille, 1798)",
        mte_catalog_number: "GBIFCH00995787",
        user_id: actor.id,
        version_action_name: :import,
        version_action_type: :create
      },
      %{
        tax_scientific_name: "Aphaenogaster subterranea (Latreille, 1798)",
        mte_catalog_number: "GBIFCH00995788",
        user_id: actor.id,
        version_action_name: :import,
        version_action_type: :create
      },
      %{
        tax_scientific_name: "Anergates atratulus (Schenck, 1852)",
        mte_catalog_number: "GBIFCH00993799",
        user_id: actor.id,
        version_action_name: :import,
        version_action_type: :create
      }
    ]

    # duplicate expected versions for each iteration > 0
    expected = 1..iterations |> Enum.map(fn _ -> expected end) |> List.flatten()

    assert_lists_equal(expected, versions)
  end

  # versions for one encoding iteration
  defp assert_encode_versions(actor, tenant) do
    encoded_records = Ash.read!(EncodedRecord, load: [:paper_trail_versions], tenant: tenant)
    assert length(encoded_records) == 6

    versions =
      encoded_records
      |> Enum.map(& &1.paper_trail_versions)
      |> List.flatten()
      |> Enum.map(
        &Map.take(&1, [
          :version_action_name,
          :version_action_type,
          :user_id
        ])
      )

    expected_length = 6 * @catalog_versions
    assert length(versions) == expected_length

    # Ensure all strategies set the user_id correctly
    for index <- 0..(expected_length - 1) do
      version = Enum.at(versions, index)
      assert version.user_id == actor.id
    end
  end

  defp assert_no_encode_verions(tenant) do
    encoded_records = Ash.read!(EncodedRecord, load: [:paper_trail_versions], tenant: tenant)
    assert length(encoded_records) == 6

    versions =
      encoded_records
      |> Enum.map(& &1.paper_trail_versions)
      |> List.flatten()
      |> Enum.map(
        &Map.take(&1, [
          :version_action_name,
          :version_action_type,
          :user_id
        ])
      )

    expected_length = 0
    assert length(versions) == expected_length
  end

  defp assert_changes(records) do
    changes =
      records
      |> hd()
      |> Ash.load!([changes: [transform?: true, escape_nil?: true]], strict?: true, lazy?: true)
      |> Map.get(:changes)

    changes =
      Enum.reduce(changes, [], fn {key, value}, acc ->
        if key == :oth_swiss_species_registered_at do
          [{key, Map.put(value, :encoded, "test")} | acc]
        else
          [{key, value} | acc]
        end
      end)

    expected = [
      tax_taxon_id: %{
        name: "taxonID",
        imported: "-",
        encoded: 2_435_194,
        category_name: "tax"
      },
      tax_scientific_name: %{
        name: "scientificName",
        imported: "Anergates atratulus (Schenck, 1852)",
        encoded: "Oenanthe Vieillot, 1816",
        category_name: "tax"
      },
      tax_family: %{
        name: "family",
        imported: "-",
        encoded: "Muscicapidae",
        category_name: "tax"
      },
      tax_genus: %{
        name: "genus",
        imported: "Anergates",
        encoded: "Oenanthe",
        category_name: "tax"
      },
      tax_order: %{
        name: "order",
        imported: "-",
        encoded: "Passeriformes",
        category_name: "tax"
      },
      loc_continent: %{
        name: "continent",
        imported: "-",
        encoded: "Europe",
        category_name: "loc"
      },
      tax_accepted_name_usage: %{
        name: "acceptedNameUsage",
        imported: "-",
        encoded: "Enantiulus dentigerus (Verhoeff, 1901)",
        category_name: "tax"
      },
      tax_class: %{
        name: "class",
        imported: "-",
        encoded: "Aves",
        category_name: "tax"
      },
      tax_phylum: %{
        name: "phylum",
        imported: "-",
        encoded: "Chordata",
        category_name: "tax"
      },
      tax_taxon_id_ch: %{
        name: "taxonIdCH",
        imported: "-",
        encoded: 15_311,
        category_name: "tax"
      },
      iucn_redlist_category: %{
        name: :iucn_redlist_category,
        imported: "-",
        encoded: "EX",
        category_name: "iucn"
      },
      loc_country_code: %{
        name: "countryCode",
        imported: "ch",
        encoded: "CH",
        category_name: "loc"
      },
      tax_accepted_name_usage_id: %{
        name: "acceptedNameUsageID",
        imported: "-",
        encoded: "1669856",
        category_name: "tax"
      },
      eve_event_date: %{
        name: "eventDate",
        imported: "2025-01-01/2025-01-20",
        encoded: "1907-06-06",
        category_name: "eve"
      },
      oth_swiss_species_center: %{
        name: "swissSpeciesCenter",
        imported: "-",
        encoded: "infofauna",
        category_name: "oth"
      },
      oth_swiss_species_registered: %{
        name: "swissSpeciesRegistered",
        imported: "-",
        encoded: true,
        category_name: "oth"
      },
      oth_swiss_species_registered_at: %{
        name: "swissSpeciesRegisteredAt",
        imported: "-",
        encoded: "test",
        category_name: "oth"
      }
    ]

    assert_lists_equal(expected, changes)
  end
end
