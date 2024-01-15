defmodule DataAggregator.Records.Encoding.Strategy do
  @moduledoc """
    This module is responsible for encoding records with configured catalogs.

    To encode records with a new catalog, add the catalog to the @catalogs list and
    implement the encode/2 function with the corresponding `when` statement

    to keep this module clean, the actual encoding logic is delegated to a
    strategy module like we do with the `DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy` or the `DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy` module
  """
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy
  alias DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy
  alias DataAggregator.Records.Record

  @catalogs [:gbif_taxonomy, :swiss_species]

  def get_catalogs, do: @catalogs

  @spec encode(Record.t(), atom()) :: {:ok, EncodedRecord.t()} | {:error, any()}
  def encode(record, catalog) when catalog == :gbif_taxonomy do
    encoded_record = create_encoded_record(record)

    GbifTaxonomyStrategy.apply_strategy(encoded_record)
  end

  @spec encode(Record.t(), atom()) :: {:ok, EncodedRecord.t()} | {:error, any()}
  def encode(record, catalog) when catalog == :swiss_species do
    encoded_record = create_encoded_record(record)

    SwissSpeciesStrategy.apply_strategy(encoded_record)
  end

  # create an encoded record if it does not exist yet
  @spec create_encoded_record(Record.t()) :: EncodedRecord.t()
  def create_encoded_record(record) do
    encoded_record =
      case EncodedRecord.get_by_record(record) do
        {:ok, result} -> result
        {:error, %Ash.Error.Query.NotFound{}} -> nil
      end

    case encoded_record do
      nil ->
        EncodedRecord.create!(
          Map.from_struct(record)
          |> Map.put_new_lazy(:record, fn -> record end)
        )

      _ ->
        encoded_record
    end
  end

  @spec update_encoded_record(map(), EncodedRecord.t(), list()) :: EncodedRecord.t()
  def update_encoded_record(updated_values, record, output_attributes) do
    updated_attributes =
      Enum.map(output_attributes, fn {record_attribute, catalog_attribute} ->
        {record_attribute, Map.get(updated_values, catalog_attribute)}
      end)
      |> Enum.into(%{})

    EncodedRecord.update!(record, updated_attributes)
  end
end
