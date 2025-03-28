defmodule DataAggregatorApi.Router do
  use Phoenix.Router, helpers: false

  pipeline :api do
    plug :accepts, ["json"]
    plug :get_tenant_from_path
    plug :get_actor_from_token
  end

  scope "/json" do
    pipe_through :api

    forward "/swagger",
            OpenApiSpex.Plug.SwaggerUI,
            path: "/api/json/open_api",
            title: "Data Aggregator JSON-API - Swagger UI",
            default_model_expand_depth: 4

    forward "/redoc",
            Redoc.Plug.RedocUI,
            spec_url: "/api/json/open_api"

    forward "/", DataAggregatorApi.JsonApi.Router
  end

  @spec get_actor_from_token(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def get_actor_from_token(conn, _opts) do
    with ["" <> token] <- get_req_header(conn, "api_key"),
         {:ok, %{"sub" => sub}, resource} <-
           AshAuthentication.Jwt.verify(token, :data_aggregator),
         {:ok, user} <-
           AshAuthentication.subject_to_user(sub, resource) do
      Ash.PlugHelpers.set_actor(conn, user)
    else
      _ -> conn
    end
  end

  @doc """
  Get the tenant from the path and set it on the connection.

  path_info comes like this ["json", "datasets", set_02zJRhVkz8Z93Wtk95k7dM, "more"] if it's tenant specific

  the tenant is always the third element in the path_info, as long as the path is tenant specific. if not, the default connection is returned

      ## Example
      iex> conn = %Plug.Conn{ path_info: ["json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM", "records"] }
      iex> get_tenant_from_path(conn, [])
      %Plug.Conn{private: %{ash: %{tenant: "set_02zJRhVkz8Z93Wtk95k7dM"}}, path_info: ["json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM", "records"]}

      iex> conn = %Plug.Conn{ path_info: ["json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM"] }
      iex> get_tenant_from_path(conn, [])
      %Plug.Conn{private: %{ash: %{tenant: "set_02zJRhVkz8Z93Wtk95k7dM"}}, path_info: ["json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM"]}

      iex> conn = %Plug.Conn{ path_info: ["json", "datasets"] }
      iex> get_tenant_from_path(conn, [])
      %Plug.Conn{path_info: ["json", "datasets"]}

      iex> conn = %Plug.Conn{ path_info: ["json"] }
      iex> get_tenant_from_path(conn, [])
      %Plug.Conn{path_info: ["json"]}

      iex> conn = %Plug.Conn{ path_info: [] }
      iex> get_tenant_from_path(conn, [])
      %Plug.Conn{path_info: []}

      iex> conn = %Plug.Conn{ path_info: nil }
      iex> get_tenant_from_path(conn, [])
      %Plug.Conn{path_info: nil}

  """
  @spec get_tenant_from_path(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def get_tenant_from_path(%{path_info: path_info} = conn, _opts) do
    {json, datasets, tenant} = split_path_info(path_info)

    cond do
      json != "json" ->
        conn

      datasets != "datasets" ->
        conn

      tenant == nil ->
        conn

      true ->
        Ash.PlugHelpers.set_tenant(conn, tenant)
    end
  end

  @doc """
  Split the path_info into "json", "datasets", and the tenant (collection_id)

      ## Example
      iex> split_path_info(["json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM", "more"])
      {"json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM"}

      iex> split_path_info(["json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM"])
      {"json", "datasets", "set_02zJRhVkz8Z93Wtk95k7dM"}

      iex> split_path_info(["json", "datasets"])
      {"json", "datasets", nil}

      iex> split_path_info(["json"])
      {"json", nil, nil}

      iex> split_path_info([])
      {nil, nil, nil}

      iex> split_path_info(nil)
      {nil, nil, nil}

      iex> split_path_info("json")
      {nil, nil, nil}

      iex> split_path_info(100)
      {nil, nil, nil}

      iex> split_path_info(true)
      {nil, nil, nil}
  """
  def split_path_info(nil), do: {nil, nil, nil}
  def split_path_info([]), do: {nil, nil, nil}
  def split_path_info(path_info) when not is_list(path_info), do: {nil, nil, nil}

  def split_path_info(path_info) do
    {Enum.at(path_info, 0), Enum.at(path_info, 1), Enum.at(path_info, 2)}
  end
end
