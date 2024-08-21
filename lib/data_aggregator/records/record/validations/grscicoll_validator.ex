defmodule DataAggregator.Records.Validations.GrSciCollValidator do
  @moduledoc """
  Validates if agiven collection "code" is a valid reference to a GrSciColl collection
  """

  use Ash.Resource.Validation

  alias DataAggregator.Gbif

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
  def validate(changeset, opts, _ctx) do
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
    case Gbif.RestAPI.get_grscicoll_entity(key, kind) do
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
end
