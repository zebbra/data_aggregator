defmodule DataAggregator.EmlFileTest do
  @moduledoc false

  use DataAggregator.DataCase, async: true
  use Mimic

  import DataAggregator.EncodingFixtures
  import DataAggregator.RecordsFixtures

  alias DataAggregator.DarwinCore.Publication.EmlFile
  alias DataAggregator.Gbif
  alias DataAggregator.Gbif.RestAPIStub
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records.Publication

  describe "eml file tests" do
    setup do
      stub_with(Gbif.RestAPI, RestAPIStub)

      collection = collection_fixture(%{name: "Collection NumberO!+ne"})

      collection_no_contact =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.no_contact_grscicoll_reference()
        })

      collection_no_creator =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.no_creator_grscicoll_reference()
        })

      collection_no_contact_creator =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.no_contact_creator_grscicoll_reference()
        })

      collection_multiple_contacts =
        collection_fixture(%{
          grscicoll_reference: RestAPIStub.multiple_contacts_grscicoll_reference()
        })

      record1 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 10.0,
          loc_decimal_longitude: 10.0
        })

      record2 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 166.4713889,
          loc_decimal_longitude: 640_000.0
        })

      record3 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia",
          loc_decimal_latitude: 47.27606815,
          loc_decimal_longitude: 9.408043484
        })

      record4 =
        record_fixture(%{
          collection: collection,
          mte_catalog_number: "catalog-number-#{Uniq.UUID.uuid7(:slug)}",
          tax_kingdom: "Animalia"
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

      records = [
        Ash.load!(record1, [:encoded_record]),
        Ash.load!(record2, [:encoded_record]),
        Ash.load!(record3, [:encoded_record]),
        Ash.load!(record4, [:encoded_record]),
        Ash.load!(record5, [:encoded_record])
      ]

      query = %{
        collection: %{id: %{eq: collection.id}},
        encoded_record: %{tax_kingdom: %{is_nil: false}}
      }

      publication =
        Publication.create!(
          %{
            name: "Publication Fast Track 2",
            channel: :fast_track,
            records_query: query,
            collection: collection
          },
          tenant: collection
        )

      path = FlatFileUtils.create_directory!("publication_#{publication.channel}")

      [
        collection: collection,
        collection_no_contact: collection_no_contact,
        collection_no_creator: collection_no_creator,
        collection_no_contact_creator: collection_no_contact_creator,
        collection_multiple_contacts: collection_multiple_contacts,
        records: records,
        publication: publication,
        path: path
      ]
    end

    test "create/2 successful with contact and creator", %{
      publication: publication,
      collection: collection,
      path: path
    } do
      {:ok, path} = EmlFile.create(collection, publication.license, path)

      {:ok, xmldoc} = File.read(path)

      assert String.contains?(
               xmldoc,
               "<creator><individualName><givenName>TestCreator</givenName><surName>McTest</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><positionName>Curator</positionName><address><city>Zürich</city><country>CH</country></address><role>test role</role><role>creator</role><electronicMailAddress>test.testy@systbot.uzh.ch</electronicMailAddress></creator>"
             )

      assert String.contains?(
               xmldoc,
               "<contact><individualName><givenName>TestContact</givenName><surName>McTest</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><positionName>contact</positionName><address><city>Zürich</city><country>CH</country></address><electronicMailAddress>test.testy@systbot.uzh.ch</electronicMailAddress></contact>"
             )
    end

    test "create/2 successful no contact", %{
      publication: publication,
      collection_no_contact: collection,
      path: path
    } do
      {:ok, path} = EmlFile.create(collection, publication.license, path)

      {:ok, xmldoc} = File.read(path)

      assert String.contains?(
               xmldoc,
               "<creator><individualName><givenName>TestCreator</givenName><surName>McTest</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><positionName>creator</positionName><address><city>Zürich</city><country>CH</country></address><electronicMailAddress>test.testy@systbot.uzh.ch</electronicMailAddress></creator>"
             )

      refute String.contains?(xmldoc, "<metadataProvider>")

      assert String.contains?(
               xmldoc,
               "<contact><individualName><givenName>n/a</givenName><surName>n/a</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><address><deliveryPoint/><city>Zürich</city><postalCode>CH-8008</postalCode><country>CH</country></address><phone>[41] 44 634 84 11</phone><electronicMailAddress>n/a</electronicMailAddress></contact>"
             )
    end

    test "create/2 successful no creator", %{
      publication: publication,
      collection_no_creator: collection,
      path: path
    } do
      {:ok, path} = EmlFile.create(collection, publication.license, path)

      {:ok, xmldoc} = File.read(path)

      refute String.contains?(xmldoc, "<creator>")
      refute String.contains?(xmldoc, "<metadataProvider>")

      assert String.contains?(
               xmldoc,
               "<contact><individualName><givenName>TestContact</givenName><surName>McTest</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><positionName>contact</positionName><address><city>Zürich</city><country>CH</country></address><electronicMailAddress>test.testy@systbot.uzh.ch</electronicMailAddress></contact>"
             )
    end

    test "create/2 successful no creator no contact", %{
      publication: publication,
      collection_no_contact_creator: collection,
      path: path
    } do
      {:ok, path} = EmlFile.create(collection, publication.license, path)

      {:ok, xmldoc} = File.read(path)

      refute String.contains?(xmldoc, "<creator>")
      refute String.contains?(xmldoc, "<metadataProvider>")

      assert String.contains?(
               xmldoc,
               "<contact><individualName><givenName>n/a</givenName><surName>n/a</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><address><deliveryPoint/><city>Zürich</city><postalCode>CH-8008</postalCode><country>CH</country></address><phone>[41] 44 634 84 11</phone><electronicMailAddress>n/a</electronicMailAddress></contact>"
             )
    end

    test "create/2 successful multiple contacts", %{
      publication: publication,
      collection_multiple_contacts: collection,
      path: path
    } do
      {:ok, path} = EmlFile.create(collection, publication.license, path)

      {:ok, xmldoc} = File.read(path)

      refute String.contains?(xmldoc, "<creator>")
      refute String.contains?(xmldoc, "<metadataProvider>")

      assert String.contains?(
               xmldoc,
               "<contact><individualName><givenName>TestContact1</givenName><surName>McTest</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><positionName>contact</positionName><address><city>Zürich</city><country>CH</country></address><electronicMailAddress>test.testy@systbot.uzh.ch</electronicMailAddress></contact><contact><individualName><givenName>TestContact2</givenName><surName>McTest</surName></individualName><organizationName>Herbarium of the University of Zürich</organizationName><positionName>contact</positionName><address><city>Zürich</city><country>CH</country></address><electronicMailAddress>test.testy@systbot.uzh.ch</electronicMailAddress></contact>"
             )
    end
  end
end
