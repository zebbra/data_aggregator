defmodule DataAggregator.DarwinCore.Publication.MetaFile do
  @moduledoc """
  Module to create a Metadata xml file according to gbif (https://dwc.tdwg.org/text/) for a Darwin Core Archive (DwCA)
  Which holds information about how single xml files are structured and how they are related to each other
  """
  import XmlBuilder

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.DarwinCore.Schema.DwcAttribute
  alias DataAggregator.Records.Collection

  @dwca_extension_file_types [
    material_sample: {"material_sample.csv", "http://rs.tdwg.org/dwc/terms/MaterialSample"},
    preservation: {"preservation.csv", "http://rs.tdwg.org/dwc/terms/MeasurementOrFact"},
    releve: {"releve.csv", "http://rs.tdwg.org/dwc/terms/Event"}
  ]

  @spec create(Collection.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def create(_collection, path) do
    path = path <> "/meta.xml"

    create_meta_file(build(), path)

    {:ok, path}
  end

  defp create_meta_file(content, path) do
    file = File.open!(path, [:write, :utf8])

    IO.write(file, content)
    File.close(file)

    file
  end

  # generates the root xml element "archive" for the meta.xml file
  defp build do
    {:archive,
     [
       xmlns: "http://rs.tdwg.org/dwc/text/",
       "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
       "xmlns:xs": "http://www.w3.org/2001/XMLSchema",
       "xsi:schemaLocation": "http://rs.tdwg.org/dwc/text/ http://rs.tdwg.org/dwc/text/tdwg_dwc_text.xsd"
     ],
     [
       core()
       | extensions()
     ]}
    |> document()
    |> generate(format: :pretty)
  end

  # generates the core xml element for the meta.xml file
  defp core do
    element(
      :core,
      %{
        encoding: "UTF-8",
        fieldsTerminatedBy: ",",
        ignoreHeaderLines: "1",
        rowType: "http://rs.tdwg.org/dwc/terms/Occurrence"
      },
      [
        files_element("core.csv"),
        element(:id, %{index: "0"})
        | field_elements(:core)
      ]
    )
  end

  # generates the extension xml elements for the meta.xml file
  def extensions do
    Enum.map(@dwca_extension_file_types, fn {dwca_file_type, {file_path, row_type}} ->
      children = [
        files_element(file_path),
        core_id_element() | field_elements(dwca_file_type)
      ]

      element(
        :extension,
        %{
          encoding: "UTF-8",
          fieldsTerminatedBy: ",",
          ignoreHeaderLines: "1",
          rowType: row_type
        },
        children
      )
    end)
  end

  defp files_element(file_path) do
    element(
      :files,
      [
        element(:location, file_path)
      ]
    )
  end

  defp core_id_element do
    element(:coreid, %{index: "0"})
  end

  @spec field_elements(atom()) :: [map()]
  defp field_elements(dwca_file_type) do
    dwc_links = dwc_links(dwca_file_type)

    build_field_elements(dwc_links)
  end

  @spec build_field_elements([String.t()]) :: [map()]
  defp build_field_elements(dwc_links) do
    for i <- amount_of_fields_range(dwc_links) do
      dwc_link = Enum.at(dwc_links, i)

      element(:field, %{index: i, term: dwc_link})
    end
  end

  @spec amount_of_fields_range([String.t()]) :: [integer()]
  defp amount_of_fields_range(dwc_links) do
    Enum.to_list(0..(length(dwc_links) - 1))
  end

  @spec dwc_links(atom()) :: [String.t()]
  defp dwc_links(dwca_file_type) do
    dwca_attributes = dwca_attribute(dwca_file_type)

    [
      "http://rs.tdwg.org/dwc/terms/occurrenceID"
      | Enum.map(dwca_attributes, fn dwca_attribute -> dwca_attribute.dwc_link end)
    ]
  end

  # returns all dwca attributes for a given dwca file type if they have a dwc_field and dwc_link
  # and if it's not the occurrenceID, b'cause this is the ID and will be the set as the first column
  @spec dwca_attribute(atom()) :: [DwcAttribute.t()]
  defp dwca_attribute(dwca_file_type) do
    dwca_file_type
    |> Schema.dwc_attributes_by_dwca_file_type()
    |> Enum.filter(&(&1.dwc_field != nil and &1.dwc_link != nil and &1.dwc_field != "occurrenceID"))
  end
end
