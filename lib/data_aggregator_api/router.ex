defmodule DataAggregatorApi.Router do
  use Phoenix.Router, helpers: false

  pipeline :api do
    plug :accepts, ["json"]

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
end
