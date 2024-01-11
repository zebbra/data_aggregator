defmodule DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy do
  @moduledoc """
    Encode Records with the gbif swiss species registry catalog
  """

  require Logger

  alias DataAggregator.Records.EncodedRecord

  # the input attributes are the attributes that will be used to find the
  # matching species in the catalog.
  # the first element is the attribute on the encoded record and the second
  # is the attribute to be used from the returning data structure
  # @input_attributes [
  #   {:tax_taxon_id, :name}
  # ]

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  # @output_attributes [
  #   {:tax_kingdom, :kingdom},
  #   {:tax_phylum, :phylum},
  #   {:tax_class, :class},
  #   {:tax_family, :family},
  #   {:tax_order, :order},
  #   {:tax_genus, :genus},
  #   {:tax_scientific_name, :scientificName}
  # ]

  @doc """
    lookup the gbif swiss species registry and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t()) :: {:ok, EncodedRecord.t()} | {:error, any()}
  def apply_strategy(record) do
    process_record(record)
  end

  @spec process_record(EncodedRecord.t()) :: {:ok, EncodedRecord.t()} | {:error, any()}
  defp process_record(record) do
    {:ok, record}
  catch
    error ->
      {:error, error}
  end

  # @spec throw_error(map()) :: {:ok, map()} | {:error, any()}
  # defp throw_error(error) do
  #   Logger.error("Error while fetching gbif taxonomy api: #{inspect(error)}")

  #   throw(error)
  # end
end
