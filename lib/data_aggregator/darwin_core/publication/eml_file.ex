defmodule DataAggregator.DarwinCore.Publication.EmlFile do
  @moduledoc """
  Module to create a Metadata Profile xml file according to gbif (https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile) for a Darwin Core Archive (DwCA)
  Which holds meta information about the published dataset
  """
  import XmlBuilder

  alias DataAggregator.Records.Collection

  @spec create(Collection.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def create(collection, path) do
    path = path <> "/eml.xml"

    # XmlBuilder.document("", "Josh") |> XmlBuilder.generate()
    # TODO: implement the creation of the eml.xml file
    # file = xyz.create_file!(:eml, ...)

    create_eml_file(collection, path)

    {:ok, path}
  end

  def create_eml_file(collection, path) do
    file = File.open!(path, [:write, :utf8])

    IO.write(file, build(collection))

    File.close(file)

    file
  end

  defp build(collection) do
    {:"eml:eml",
     [
       "xmlns:eml": "eml://ecoinformatics.org/eml-2.1.1",
       "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
       "xsi:schemaLocation": "eml://ecoinformatics.org/eml-2.1.1 http://rs.gbif.org/schema/eml-gbif-profile/1.2/eml.xsd",
       packageId: collection.gbif_dataset_key,
       system: "http://gbif.org",
       scope: "system"
     ],
     [
       dataset(collection)
     ]}
    |> document()
    |> generate(format: :none)
  end

  defp dataset(collection) do
    element(:dataset,
      title: collection.name,
      creator: [
        individualName: [givenName: "John", surName: "Doe"],
        organizationName: "Info Flora",
        address: [
          deliveryPoint: "c/o Botanischer Garten",
          city: "Bern",
          postalCode: "CH-3013",
          country: "SWITZERLAND"
        ],
        electronicMailAddress: "john.doe@boga.ch"
      ],
      pubDate: "2019-01-01",
      language: "ENGLISH",
      abstract: [
        para: "This dataset is maintained by Info Flora (National Data and Information Center of Swiss
        Flora), a member of Info Species. It includes records of vascular plants from Switzerland
        and the adjacent area. Data sources include field observations provided by a large network
        of volunteer collaborators, environmental impact studies, national inventories (Red List
        strategy), museum collections, literature and academic work. The period covered by the data
        extends from 1700 to the present day. All data provided have been subject to a validation
        procedure."
      ],
      intellectualRights: [
        element(para: {:safe, "This work is licensed under a <ulink
          url=\"http://creativecommons.org/licenses/by/4.0/legalcode\">
          <citetitle>Creative Commons Attribution (CC-BY) 4.0 License</citetitle>
        </ulink>. "})
      ],
      distribution: [
        online: [element(:url, %{function: "information"}, "http://www.infoflora.ch")]
      ],
      maintenance: [description: [para: []], maintenanceUpdateFrequency: "unkown"],
      contact: [
        individualName: [givenName: "John", surName: "Doe"]
      ]
      # creator: [
      #   individualName: [givenName: "John", surName: "Doe"],
      #   organizationName: "Info Flora",
      #   address: [
      #     deliveryPoint: "c/o Botanischer Garten",
      #     city: "Bern",
      #     postalCode: "CH-3013",
      #     country: "SWITZERLAND"
      #   ],
      #   electronicMailAddress: "john.doe@boga.ch"
      # ],
      # pubDate: "2019-01-01",
      # language: "ENGLISH",
      # abstract: [para: "Dataset abstract"]

      # metadataProvider: [
      #   individualName: [givenName: "John", surName: "Doe"],
      #   organizationName: "Infor Flora",
      #   address: [
      #     deliveryPoint: "c/o Botanischer Garten",
      #     city: "Bern",
      #     postalCode: "CH-3013",
      #     country: "SWITZERLAND"
      #   ],
      #   electronicMailAddress: "john.doe@bla.com"
      # ],
      # pubDate: "2019-01-01",
      # language: "ENGLISH",
      # abstract: [para: "Dataset abstract"]
    )
  end
end
