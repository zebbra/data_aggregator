defmodule DataAggregatorApi.Router do
  use Phoenix.Router, helpers: false

  pipeline :api do
    plug :accepts, ["json"]
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
end
