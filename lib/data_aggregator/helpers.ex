defmodule DataAggregator.Helpers do
  @moduledoc """
  Generic helpers for the DataAggregator application.
  """

  import Ash.Expr

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Record

  require Ash.Query

  @doc """
  Returns a list of distinct values for a given field in a resource.
  """
  @spec distinct(Ash.Resource.t() | Ash.Query.t(), atom()) :: [String.t()]
  def distinct(resource_or_query, field) do
    resource_or_query
    |> Ash.Query.filter(^ref(field) != "")
    |> Ash.Query.distinct(field)
    |> Ash.Query.distinct_sort(field)
    |> Ash.Query.select(field)
    |> Ash.read!()
    |> Enum.map(&Map.get(&1, field))
  end

  @doc """
  Returns a list of distinct values for a given field in a resource.
  Bypasses ash orm and directly queries the database.
  """
  def distinct_ecto(field, table, collection) do
    query = """
      SELECT DISTINCT "#{field}" FROM "#{table}" WHERE "#{field}" IS NOT NULL AND collection_id = $1
    """

    case run_ecto_query(query, [ecto_binary(collection.id)]) do
      %Postgrex.Result{num_rows: 0} ->
        []

      %Postgrex.Result{rows: distinct_values} ->
        List.flatten(distinct_values)

      _ ->
        []
    end
  end

  defp ecto_binary(id) do
    with [_prefix, b62_string_uuid] <- String.split(id, "_"),
         {:ok, string_uuid} <- AshUUID.Encoder.decode(b62_string_uuid),
         {:ok, binary} <- Ecto.UUID.dump(string_uuid) do
      binary
    end
  end

  defp run_ecto_query(query, params) do
    Ecto.Adapters.SQL.query!(DataAggregator.Repo, query, params)
  end

  @doc """
  Loads the record relation for a given resource if it is not already loaded.
  """
  def maybe_performant_load_record(resource, tenant, load \\ nil)

  def maybe_performant_load_record(%{record: %Ash.NotLoaded{}, record_id: record_id} = resource, tenant, load) do
    record = Record.get_by_id!(record_id, tenant: tenant, load: load)
    %{resource | record: record}
  end

  def maybe_performant_load_record(resource, _tenant, _load), do: resource

  @doc """
  Generate a map from a user which can be passed as an actor to a worker.
  """
  @spec actor_map(User.t()) :: map()
  def actor_map(actor) when is_struct(actor) do
    actor
    |> Map.from_struct()
    |> Map.take([:id, :institution_id, :roles])
  end

  def actor_map(actor), do: actor
end
