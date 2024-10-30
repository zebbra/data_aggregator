defmodule DataAggregator.Records.Encoding.Strategy do
  @moduledoc """
    This module is responsible for encoding records with configured catalogs.

    At this point, the encoded_record must already exist in the database. It
    is created / upserted during the import process. Thus, we simply
    fetch the encoded_record from the database and pass it to the encoding.

    To encode records with a new catalog, add the catalog to the @catalogs list and
    implement the encode/2 function with the corresponding `when` statement

    to keep this module clean, the actual encoding logic is delegated to a
    strategy module like we do with the `DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy`
    or the `DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy` module
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Encoding.Strategy.AddInstitutionCodeStrategy
  alias DataAggregator.Records.Encoding.Strategy.ForwardGeoEncodingStrategy
  alias DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy
  alias DataAggregator.Records.Encoding.Strategy.IUCNRedlistStrategy
  alias DataAggregator.Records.Encoding.Strategy.RelateImagesStrategy
  alias DataAggregator.Records.Encoding.Strategy.ReverseGeoEncodingStrategy
  alias DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @doc """
  Attention! For the first catalog we reset the encoded_record to the record's value.
  As of now, the first catalog is the gbif_taxonomy catalog. If this changes, the
  first catalog must be updated here as well.
  """
  @spec encode(Record.t() | EncodedRecord.t(), atom(), Context.t()) :: EncodingResult.t()
  def encode(record_or_encoded_record, catalog, ctx)

  def encode(%Record{} = record, catalog, ctx) when catalog == :gbif_taxonomy do
    attributes =
      [
        :extra_data,
        :iucn_redlist_category
      ] ++ DataAggregator.DarwinCore.Schema.prefixed_attribute_names()

    encoded_record =
      EncodedRecord.create!(
        record
        |> Map.from_struct()
        |> Map.take(attributes)
        |> Map.put_new_lazy(:record, fn -> record end)
      )

    encode(encoded_record, catalog, ctx)
  end

  def encode(%Record{} = record, catalog, ctx) do
    encoded_record = EncodedRecord.get_by_record!(record.id)
    encode(encoded_record, catalog, ctx)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :gbif_taxonomy do
    encoded_record
    |> GbifTaxonomyStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :swiss_species do
    encoded_record
    |> SwissSpeciesStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :geo_reverse do
    encoded_record
    |> ReverseGeoEncodingStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :geo_forward do
    encoded_record
    |> ForwardGeoEncodingStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :gbif_iucn_redlist do
    encoded_record
    |> IUCNRedlistStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :add_institution_code do
    encoded_record
    |> AddInstitutionCodeStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) when catalog == :relate_images do
    encoded_record
    |> RelateImagesStrategy.apply_strategy(ctx)
    |> check_for_changes(encoded_record, catalog)
    |> handle_encoding_result(encoded_record, catalog)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, _ctx) do
    {:error, "no encoding strategy found for catalog: #{inspect(catalog)}", encoded_record}
  end

  @spec handle_encoding_result(EncodingResult.t(), EncodedRecord.t(), atom()) ::
          EncodingResult.t()
  defp handle_encoding_result(encoding_result, old_record, catalog) do
    attrs =
      %{
        catalog: catalog
      }

    case encoding_result do
      {:ok, new_record} ->
        create_success_result(attrs, catalog, old_record, new_record)

        {:ok, new_record}

      {:unchanged, unchanged_record} ->
        create_unchanged_result(attrs, catalog, old_record, unchanged_record)

        {:ok, unchanged_record}

      {:error, error, encoding_result} ->
        create_error_result(attrs, catalog, old_record, error)

        {:error, error, encoding_result}
    end
  end

  defp create_success_result(attrs, catalog, old_record, new_record) do
    record = Ash.load!(old_record, [:record], lazy?: true).record

    attrs
    |> put_input_values(catalog, old_record)
    |> put_output_values(catalog, new_record)
    |> Map.put(:state, :success)
    |> Map.put(:record, record)
    |> RecordEncodingResult.create!()
  end

  defp create_unchanged_result(attrs, catalog, old_record, unchanged_record) do
    record = Ash.load!(old_record, [:record], lazy?: true).record

    attrs
    |> put_input_values(catalog, old_record)
    |> put_output_values(catalog, unchanged_record)
    |> Map.put(:state, :unchanged)
    |> Map.put(:message, "no changes during encoding")
    |> Map.put(:record, record)
    |> RecordEncodingResult.create!()
  end

  defp create_error_result(attrs, catalog, old_record, error) do
    record = Ash.load!(old_record, [:record], lazy?: true).record
    new_record = EncodedRecord.get_by_record!(record.id)

    err_msg = get_err_msg(error)

    attrs
    |> put_input_values(catalog, old_record)
    |> put_output_values(catalog, new_record)
    |> Map.put(:state, :error)
    |> Map.put(:message, err_msg)
    |> Map.put(:record, record)
    |> RecordEncodingResult.create!()
  end

  defp get_err_msg(error) when is_binary(error) == true, do: error
  defp get_err_msg(error) when is_binary(error) == false, do: inspect(error)

  defp put_input_values(attrs, catalog, record) do
    Map.put(attrs, :input, get_values_used_for_encoding(record, catalog))
  end

  defp put_output_values(attrs, catalog, record) do
    Map.put(attrs, :output, get_encoded_values(record, catalog))
  end

  defp check_for_changes(encoding_result, original_encoded_record, catalog) do
    case encoding_result do
      {:ok, new_encoded_record} ->
        new_values = get_encoded_values(new_encoded_record, catalog)
        old_values = get_encoded_values(original_encoded_record, catalog)

        if Map.equal?(new_values, old_values) do
          Logger.debug(
            "no changes during encoding of record #{original_encoded_record.id} with catalog #{inspect(catalog)}"
          )

          {:unchanged, new_encoded_record}
        else
          {:ok, new_encoded_record}
        end

      {:error, error, encoding_result} ->
        {:error, error, encoding_result}
    end
  end

  defp get_encoded_values(encoded_record, catalog) do
    Map.take(encoded_record, Catalog.get_output_dwc_attributes(catalog))
  end

  defp get_values_used_for_encoding(encoded_record, catalog) do
    Map.take(encoded_record, Catalog.get_input_dwc_attributes(catalog))
  end

  @spec update_encoded_record(map(), EncodedRecord.t(), list(), Context.t()) ::
          EncodedRecord.t()
  def update_encoded_record(updated_values, record, output_attributes, %{actor: actor}) do
    updated_attributes =
      output_attributes
      |> Enum.map(fn {record_attribute, catalog_attribute} ->
        {record_attribute, updated_values[catalog_attribute]}
      end)
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.uniq()
      |> Map.new()

    EncodedRecord.update!(record, updated_attributes, actor: actor, authorize?: false)
  end
end
