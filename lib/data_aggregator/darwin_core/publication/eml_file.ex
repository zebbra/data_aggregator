defmodule DataAggregator.DarwinCore.Publication.EmlFile do
  @moduledoc """
  Module to create a Metadata Profile xml file according to gbif (https://ipt.gbif.org/manual/en/ipt/latest/gbif-metadata-profile) for a Darwin Core Archive (DwCA)
  Which holds meta information about the published dataset
  """
  import XmlBuilder

  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records.Collection

  @spec create(Collection.t(), String.t(), Collection.t()) :: {:ok, String.t()} | {:error, any()}
  def create(collection, path, _tenant) do
    with false <- collection.grscicoll_reference == nil,
         false <- collection.grscicoll_reference == "",
         {:ok, grscicoll_data} <-
           RestAPI.get_one_collection(collection.grscicoll_reference) do
      path = path <> "/eml.xml"

      xml_data = build(grscicoll_data)

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

  defp build(meta_data) do
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
       dataset(meta_data)
     ]}
    |> document()
    |> generate(format: :none)
  end

  defp dataset(meta_data) do
    element(
      :dataset,
      [
        title: meta_data["institutionCode"] <> " - " <> meta_data["name"] <> " - " <> meta_data["code"]
      ] ++
        creators(meta_data) ++
        [
          pubDate: pub_date(),
          language: "ENGLISH",
          abstract: [
            para: meta_data["notes"]
          ],
          intellectualRights: [
            element(
              para:
                {:safe,
                 "This work is licensed under a <ulink url=\"http://creativecommons.org/licenses/by/4.0/legalcode\"><citetitle>Creative Commons Attribution (CC-BY) 4.0 License</citetitle></ulink>. "}
            )
          ],
          distribution: [
            online: [element(:url, %{function: "information"}, "http://www.infoflora.ch")]
          ],
          maintenance: [description: [para: "n/a"], maintenanceUpdateFrequency: "unkown"]
        ] ++
        contacts(meta_data)
    )
  end

  defp contacts(meta_data) do
    case persons(meta_data, :contact) do
      [] ->
        [
          empty_person_element(:contact)
        ]

      creators ->
        creators
    end
  end

  defp creators(meta_data) do
    case persons(meta_data, :creator) do
      [] ->
        [
          empty_person_element(:creator)
        ]

      creators ->
        creators
    end
  end

  @spec persons(map(), atom()) :: [map()]
  defp persons(meta_data, type) do
    persons = meta_data["contactPersons"]

    if persons == nil do
      []
    else
      Enum.map(meta_data["contactPersons"], fn person ->
        element(
          type,
          [
            element(:individualName, givenName: person["firstName"], surName: person["lastName"]),
            element(:organizationName, meta_data["institutionName"]),
            address(person),
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

  defp empty_person_element(type) do
    element(
      type,
      [
        element(:individualName, givenName: "n/a", surName: "n/a"),
        element(:organizationName, "n/a"),
        element(:address, [
          element(:deliveryPoint, "n/a"),
          element(:city, "n/a"),
          element(:postalCode, "n/a"),
          element(:country, "n/a")
        ]),
        element(:phone, "n/a"),
        element(:electronicMailAddress, "n/a")
      ]
    )
  end
end
