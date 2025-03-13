defmodule DataAggregator.DarwinCore.Publication.EmlFile do
  @moduledoc """
  Module to create a Metadata Profile xml file according to gbif (https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile) for a Darwin Core Archive (DwCA)
  Which holds meta information about the published dataset
  """
  import XmlBuilder

  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication

  @spec create(Collection.t(), Publication.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def create(collection, publication, path) do
    with false <- collection.grscicoll_reference == nil,
         false <- collection.grscicoll_reference == "",
         {:ok, grscicoll_data} <-
           RestAPI.get_one_collection(collection.grscicoll_reference) do
      path = path <> "/eml.xml"

      xml_data = build(grscicoll_data, publication, collection)

      create_eml_file(xml_data, path)

      {:ok, path}
    else
      _ -> {:error, "No GBIF :grscicoll_reference key found on collection #{collection.id}"}
    end
  end

  def create_eml_file(data, path) do
    file = File.open!(path, [:write, :utf8])

    IO.write(file, data)

    File.close(file)

    file
  end

  defp build(meta_data, publication, collection) do
    {:"eml:eml",
     [
       "xmlns:eml": "eml://ecoinformatics.org/eml-2.1.1",
       "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
       "xsi:schemaLocation": "eml://ecoinformatics.org/eml-2.1.1 http://rs.gbif.org/schema/eml-gbif-profile/1.2/eml.xsd",
       packageId: meta_data["key"],
       system: "http://gbif.org",
       scope: "system"
     ],
     [
       dataset(meta_data, publication, collection)
     ]}
    |> document()
    |> generate(format: :none)
  end

  defp dataset(meta_data, %Publication{license: license}, %Collection{
         grscicoll_institution_key: grscicoll_institution_key
       }) do
    element(
      :dataset,
      [
        title: "#{meta_data["name"]} (#{meta_data["code"]}) of #{meta_data["institutionName"]}"
      ] ++
        creators(meta_data) ++
        metadata_providers(meta_data) ++
        [
          pubDate: pub_date(),
          language: "ENGLISH",
          abstract: [
            para: meta_data["notes"]
          ],
          intellectualRights: [
            element(para: {:safe, intellectual_rights(license)})
          ],
          distribution: [
            online: [
              element(
                :url,
                %{function: "information"},
                get_website(grscicoll_institution_key)
              )
            ]
          ],
          maintenance: [description: [para: "n/a"], maintenanceUpdateFrequency: "unkown"]
        ] ++
        contacts(meta_data) ++
        additional_metadata(meta_data)
    )
  end

  defp get_website(institution_key) do
    case RestAPI.get_one_institution(institution_key) do
      {:ok, institution} ->
        institution["homepage"]

      {:error, _} ->
        "n/a"
    end
  end

  defp additional_metadata(meta_data) do
    [
      element(:additionalMetadata, [
        element(:metadata, [
          element(:gbif, [
            element(:dateStamp, DateTime.to_iso8601(DateTime.utc_now())),
            element(:metadataLanguage, "English"),
            element(:hierarchyLevel, "dataset"),
            element(:parentCollectionIdentifier, meta_data["key"]),
            element(:collectionName, meta_data["name"]),
            element(
              :collectionIdentifier,
              "https://scientific-collections.gbif.org/collection/#{meta_data["key"]}"
            )
          ])
        ])
      ])
    ]
  end

  defp intellectual_rights(:cc0),
    do:
      "This work is licensed under a <ulink url=\"https://creativecommons.org/publicdomain/zero/1.0/legalcode\"><citetitle>Creative Commons Attribution (CC0) 1.0 License</citetitle></ulink>. "

  defp intellectual_rights(:cc_by),
    do:
      "This work is licensed under a <ulink url=\"http://creativecommons.org/licenses/by/4.0/legalcode\"><citetitle>Creative Commons Attribution (CC-BY) 4.0 License</citetitle></ulink>. "

  defp intellectual_rights(:cc_by_nc),
    do:
      "This work is licensed under a <ulink url=\"https://creativecommons.org/licenses/by-nc/4.0/legalcode\"><citetitle>Creative Commons Attribution (CC-BY-NC) 4.0 License</citetitle></ulink>. "

  defp contacts(meta_data) do
    case persons(meta_data, "contact") do
      [] ->
        [
          empty_person_element("contact", meta_data)
        ]

      creators ->
        creators
    end
  end

  defp creators(meta_data) do
    case persons(meta_data, "creator") do
      [] ->
        []

      creators ->
        creators
    end
  end

  defp metadata_providers(meta_data) do
    case persons(meta_data, "metadataprovider") do
      [] ->
        []

      metadata_providers ->
        metadata_providers
    end
  end

  defp persons(meta_data, type) do
    persons =
      Enum.filter(meta_data["contactPersons"], fn person ->
        person["position"]
        |> Enum.map(&String.downcase/1)
        |> Enum.member?(type)
      end)

    if persons == [] do
      []
    else
      Enum.map(persons, fn person ->
        element(
          type,
          [
            element(:individualName, givenName: person["firstName"], surName: person["lastName"]),
            element(:organizationName, meta_data["institutionName"]),
            position(person),
            address(person),
            roles(person),
            phone(person),
            email(person)
          ]
        )
      end)
    end
  end

  defp address(person) do
    element(:address, [
      delivery_point(person),
      element(:city, person["city"]),
      postal_code(person),
      element(:country, person["country"])
    ])
  end

  defp position(person) do
    case length(person["position"]) do
      0 -> nil
      _ -> element(:positionName, List.first(person["position"]))
    end
  end

  defp roles(person) do
    case length(person["position"]) do
      0 ->
        nil

      1 ->
        nil

      n ->
        person["position"]
        |> Enum.slice(1, n)
        |> Enum.map(fn role ->
          element(:role, role)
        end)
    end
  end

  defp delivery_point(person), do: concat_strings(person["address"], :deliveryPoint)

  defp postal_code(person), do: concat_strings(person["postalCode"], :postalCode)

  defp phone(person), do: concat_strings(person["phone"], :phone)

  defp email(person), do: concat_strings(person["email"], :electronicMailAddress)

  @spec concat_strings([String.t()] | nil, atom()) :: String.t() | nil
  defp concat_strings(nil, _), do: nil
  defp concat_strings([], _), do: nil

  defp concat_strings(value, attribute) when is_bitstring(value) or is_number(value) do
    element(attribute, value)
  end

  defp concat_strings(enum, attribute) do
    value = Enum.join(enum, ", ")

    element(attribute, value)
  end

  defp pub_date do
    to_string(Date.utc_today())
  end

  defp empty_person_element(type, meta_data) do
    element(
      type,
      [
        element(:individualName, givenName: "n/a", surName: "n/a"),
        element(:organizationName, meta_data["institutionName"]),
        element(:address, [
          element(:deliveryPoint, meta_data["address"]["deliveryPoint"]),
          element(:city, meta_data["address"]["city"]),
          element(:postalCode, meta_data["address"]["postalCode"]),
          element(:country, meta_data["address"]["country"])
        ]),
        element(:phone, meta_data["phone"]),
        element(:electronicMailAddress, "n/a")
      ]
    )
  end
end
