defmodule DataAggregator.Records.Validations.CollectionGrSciCollValidator do
  @moduledoc """
  Validates if agiven collection "code" is a valid reference to a GrSciColl collection
  """

  use Ash.Resource.Validation

  alias DataAggregator.Cache.HttpDiskCache

  @impl true
  def init(opts) do
    if is_atom(opts[:attribute]) do
      {:ok, opts}
    else
      {:error, "attribute must be an atom!"}
    end
  end

  @impl true
  def validate(changeset, _opts) do
    key = Ash.Changeset.get_attribute(changeset, :grscicoll_reference)

    # this is a function I made up for example

    if key == nil do
      {:error, "No valid GrSciColl reference (nil) provided"}
    else
      case does_collection_exist?(key) do
        :ok ->
          :ok

        {:error, error} ->
          # The returned error will be passed into `Ash.Error.to_ash_error/3`
          {:error, field: :grscicoll_reference, message: error}
      end
    end
  end

  @spec does_collection_exist?(String.t()) :: :ok | {:error, any()}
  defp does_collection_exist?(key) do
    case fetch_api(key) do
      {:ok, collection} ->
        if collection != nil && collection["key"] == key do
          :ok
        else
          {:error, "No valid response from GrSciColl api"}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec fetch_api(String.t()) :: {:ok, any()} | {:error, any()}
  defp fetch_api(key) do
    req = HttpDiskCache.attach(Req.new())

    url = "https://api.gbif.org/v1/grscicoll/collection/#{key}"

    # we cache requests for 10 day
    case Req.get(req, url: url, max_cache_age_seconds: 10 * 24 * 60 * 60) do
      {:ok, response} ->
        if response.status == 200 do
          {:ok, response.body}
        else
          {:error, "No valid response (status #{response.status}) from GrSciColl api"}
        end

      {:error, error} ->
        {:error, "Error during call of GrSciColl api: #{inspect(error)}"}
    end
  end
end
