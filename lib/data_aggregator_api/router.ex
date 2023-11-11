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

  pipeline :graphql do
    plug AshGraphql.Plug
  end

  scope "/graphql" do
    pipe_through :graphql

    forward "/playground",
            Absinthe.Plug.GraphiQL,
            schema: DataAggregatorApi.GraphQL.Schema,
            interface: :playground

    forward "/", Absinthe.Plug, schema: DataAggregatorApi.GraphQL.Schema
  end
end
