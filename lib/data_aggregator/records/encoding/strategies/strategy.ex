defmodule DataAggregator.Records.Encoding.Strategy do
  @moduledoc """
    This module is responsible for encoding records with configured catalogs.

    At this point, the encoded_record must already exist in the database. It
    is created / upserted during the import process. Thus, we simply
    fetch the encoded_record from the database and pass it to the encoding.

    To encode records with a new catalog, add the catalog to the @catalogs list and
    implement the encode/2 function with the corresponding `when` statement

    to keep this module clean, the actual encoding logic is delegated to a
    strategy module like we do with the `DataAggregator.Records.Encoding.Strategy.CoLTaxonomyStrategy`
    or the `DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy` module
  """

  import DataAggregator.Helpers, only: [maybe_performant_load_record: 3]

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Encoding.Strategy.CoLTaxonomyStrategy
  alias DataAggregator.Records.Encoding.Strategy.ConvertDatesStrategy
  alias DataAggregator.Records.Encoding.Strategy.ForwardGeoEncodingStrategy
  alias DataAggregator.Records.Encoding.Strategy.IUCNRedlistStrategy
  alias DataAggregator.Records.Encoding.Strategy.RelateImagesStrategy
  alias DataAggregator.Records.Encoding.Strategy.ReverseGeoEncodingStrategy
  alias DataAggregator.Records.Encoding.Strategy.SwissSpeciesStrategy
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @doc """
  Attention! For the first catalog we reset the encoded_record to the record's value.
  As of now, the first catalog is the col_taxonomy catalog. If this changes, the
  first catalog must be updated here as well.
  """
  @spec encode(Record.t() | EncodedRecord.t(), atom(), Context.t()) :: EncodingResult.t()
  def encode(record_or_encoded_record, catalog, ctx)

  def encode(%Record{} = record, :col_taxonomy, %{tenant: tenant} = ctx) do
    encoded_record = ensure_encoded_record_exists(record, tenant)
    encode(encoded_record, :col_taxonomy, ctx)
  end

  def encode(%Record{} = record, catalog, %{tenant: tenant} = ctx) do
    encoded_record = EncodedRecord.get_by_record!(record.id, tenant: tenant)
    encode(encoded_record, catalog, ctx)
  end

  def encode(%EncodedRecord{} = encoded_record, catalog, ctx) do
    case apply_catalog_strategy(encoded_record, catalog, ctx) do
      {:error, _error, _encoded_record} = error ->
        # Unknown/invalid catalogs have no input/output attributes defined,
        # so skip audit creation (handle_encoding_result) and return directly
        error

      result ->
        result
        |> check_for_changes(encoded_record, catalog)
        |> handle_encoding_result(encoded_record, catalog, ctx)
    end
  end

  @doc """
  Encodes a record with a catalog strategy without creating audit records.

  Unlike `encode/3`, this function:
  - Does NOT create `RecordEncodingResult` entries
  - Preserves the `{:unchanged, _}` return type instead of normalizing to `{:ok, _}`

  Returns `{:ok, encoded_record}`, `{:unchanged, encoded_record}`, or `{:error, error, encoded_record}`.
  """
  @spec encode_without_audit(EncodedRecord.t(), atom(), Context.t()) ::
          {:ok, EncodedRecord.t()}
          | {:unchanged, EncodedRecord.t()}
          | {:error, any(), EncodedRecord.t()}
  def encode_without_audit(%EncodedRecord{} = encoded_record, catalog, ctx) do
    encoded_record
    |> apply_catalog_strategy(catalog, ctx)
    |> check_for_changes(encoded_record, catalog)
  end

  defp apply_catalog_strategy(encoded_record, :col_taxonomy, ctx),
    do: CoLTaxonomyStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, :swiss_species, ctx),
    do: SwissSpeciesStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, :geo_reverse, ctx),
    do: ReverseGeoEncodingStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, :geo_forward, ctx),
    do: ForwardGeoEncodingStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, :iucn_redlist, ctx),
    do: IUCNRedlistStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, :relate_images, ctx),
    do: RelateImagesStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, :convert_dates, ctx),
    do: ConvertDatesStrategy.apply_strategy(encoded_record, ctx)

  defp apply_catalog_strategy(encoded_record, catalog, _ctx),
    do: {:error, "no encoding strategy found for catalog: #{inspect(catalog)}", encoded_record}

  @spec handle_encoding_result(EncodingResult.t(), EncodedRecord.t(), atom(), Context.t()) ::
          EncodingResult.t()
  defp handle_encoding_result(encoding_result, old_encoded_record, catalog, ctx) do
    attrs =
      %{
        catalog: catalog
      }

    case encoding_result do
      {:ok, new_encoded_record} ->
        create_success_result(attrs, catalog, old_encoded_record, new_encoded_record, ctx)

        {:ok, new_encoded_record}

      {:unchanged, unchanged_encoded_record} ->
        create_unchanged_result(attrs, catalog, old_encoded_record, unchanged_encoded_record, ctx)

        {:ok, unchanged_encoded_record}

      {:error, error, encoding_result} ->
        create_error_result(attrs, catalog, old_encoded_record, error, ctx)

        {:error, error, encoding_result}
    end
  end

  defp create_success_result(attrs, catalog, old_encoded_record, new_encoded_record, %{tenant: tenant}) do
    %{record: %{collection: collection} = record} =
      maybe_performant_load_record(old_encoded_record, tenant, :collection)

    attrs
    |> put_input_values(catalog, old_encoded_record)
    |> put_output_values(catalog, new_encoded_record)
    |> Map.put(:state, :success)
    |> Map.put(:record, record)
    |> Map.put(:collection, collection)
    |> RecordEncodingResult.create!(tenant: tenant)
  end

  defp create_unchanged_result(attrs, catalog, old_encoded_record, unchanged_encoded_record, %{tenant: tenant}) do
    %{record: %{collection: collection} = record} =
      maybe_performant_load_record(old_encoded_record, tenant, :collection)

    attrs
    |> put_input_values(catalog, old_encoded_record)
    |> put_output_values(catalog, unchanged_encoded_record)
    |> Map.put(:state, :unchanged)
    |> Map.put(:message, "no changes during encoding")
    |> Map.put(:record, record)
    |> Map.put(:collection, collection)
    |> RecordEncodingResult.create!(tenant: tenant)
  end

  defp create_error_result(attrs, catalog, old_encoded_record, error, %{tenant: tenant}) do
    %{record: %{collection: collection} = record} =
      maybe_performant_load_record(old_encoded_record, tenant, :collection)

    new_record = EncodedRecord.get_by_record!(record.id, tenant: tenant)

    err_msg = format_error_message(error)

    attrs
    |> put_input_values(catalog, old_encoded_record)
    |> put_output_values(catalog, new_record)
    |> Map.put(:state, :error)
    |> Map.put(:message, err_msg)
    |> Map.put(:record, record)
    |> Map.put(:collection, collection)
    |> RecordEncodingResult.create!(tenant: tenant)
  end

  @doc """
  Creates or upserts an `EncodedRecord` from a `Record`, copying over
  DarwinCore attributes, extra_data, and iucn_redlist_category.
  """
  def ensure_encoded_record_exists(record, tenant) do
    attributes =
      [:extra_data, :iucn_redlist_category] ++
        DataAggregator.DarwinCore.Schema.prefixed_attribute_names()

    record
    |> Map.from_struct()
    |> Map.take(attributes)
    |> Map.put(:record, record)
    |> EncodedRecord.create!(tenant: tenant)
  end

  @doc "Formats an error value into a string message."
  def format_error_message(error) when is_binary(error), do: error
  def format_error_message(error), do: inspect(error)

  defp put_input_values(attrs, catalog, record) do
    Map.put(attrs, :input, get_input_values(record, catalog))
  end

  defp put_output_values(attrs, catalog, record) do
    Map.put(attrs, :output, get_output_values(record, catalog))
  end

  defp check_for_changes(encoding_result, original_encoded_record, catalog) do
    case encoding_result do
      {:ok, new_encoded_record} ->
        new_values = get_output_values(new_encoded_record, catalog)
        old_values = get_output_values(original_encoded_record, catalog)

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

  @doc "Returns the output DarwinCore attribute values for the given catalog."
  def get_output_values(encoded_record, catalog) do
    Map.take(encoded_record, Catalog.get_output_dwc_attributes(catalog))
  end

  @doc "Returns the input DarwinCore attribute values for the given catalog."
  def get_input_values(encoded_record, catalog) do
    Map.take(encoded_record, Catalog.get_input_dwc_attributes(catalog))
  end

  @spec update_encoded_record(map(), EncodedRecord.t(), list(), Context.t()) ::
          EncodedRecord.t()
  def update_encoded_record(updated_values, record, [], %{actor: actor}) do
    EncodedRecord.update!(record, updated_values, actor: actor, authorize?: false)
  end

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
