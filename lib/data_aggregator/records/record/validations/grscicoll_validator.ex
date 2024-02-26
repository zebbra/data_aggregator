defmodule DataAggregator.Records.Validations.GrSciCollValidator do
  @moduledoc """
  Validates if agiven collection "code" is a valid reference to a GrSciColl collection
  """

  use Ash.Resource.Validation

  alias DataAggregator.Cache.HttpDiskCache

  @impl true
  def init(opts) do
    if attribute_is_valid?(opts[:attribute]) and kind_is_valid?(opts[:kind]) do
      {:ok, opts}
    else
      {:error, ":attribute must be an atom and :kind must be :institution or :collection"}
    end
  end

  defp kind_is_valid?(kind) do
    kind in [:institution, :collection]
  end

  defp attribute_is_valid?(attribute) do
    is_atom(attribute)
  end

  @impl true
  def validate(changeset, opts) do
    key = Ash.Changeset.get_attribute(changeset, opts[:attribute])
    kind = opts[:kind]

    if key == nil do
      {:error, "No valid GrSciColl reference (nil) provided"}
    else
      case does_grscicoll_element_exist?(key, kind) do
        :ok ->
          :ok

        {:error, error} ->
          # The returned error will be passed into `Ash.Error.to_ash_error/3`
          {:error, field: opts[:attribute], message: error}
      end
    end
  end

  @spec does_grscicoll_element_exist?(String.t(), atom()) :: :ok | {:error, any()}
  defp does_grscicoll_element_exist?(key, kind) do
    case fetch_api(key, kind) do
      {:ok, element} ->
        if element != nil && element["key"] == key do
          :ok
        else
          {:error, "No valid (empty) response from GrSciColl api"}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @spec fetch_api(String.t(), atom()) :: {:ok, any()} | {:error, any()}
  defp fetch_api(key, kind) do
    req = HttpDiskCache.attach(Req.new())

    url = "https://api.gbif.org/v1/grscicoll/#{Atom.to_string(kind)}/#{key}"

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
