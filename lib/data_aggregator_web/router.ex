defmodule DataAggregatorWeb.Router do
  use DataAggregatorWeb, :router

  import AshAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DataAggregatorWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug AshGraphql.Plug
  end

  scope "/", DataAggregatorWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/imports", ImportLive.Index, :index
    live "/imports/new", ImportLive.Index, :new
    live "/imports/:id/edit", ImportLive.Index, :edit
    live "/imports/:id", ImportLive.Show, :show
    live "/imports/:id/show/edit", ImportLive.Show, :edit
  end

  scope "/" do
    pipe_through :browser
    ash_admin "/admin"
  end

  scope "/" do
    pipe_through :graphql

    forward "/gql", Absinthe.Plug, schema: DataAggregator.Schema

    forward "/playground",
            Absinthe.Plug.GraphiQL,
            schema: DataAggregator.Schema,
            interface: :playground
  end

  scope "/api/json" do
    pipe_through(:api)

    forward "/", DataAggregatorWeb.JsonApiRouter
  end

  scope "/api" do
    forward "/swaggerui",
            OpenApiSpex.Plug.SwaggerUI,
            path: "/api/json/open_api",
            title: "Myapp's JSON-API - Swagger UI",
            default_model_expand_depth: 4

    forward "/redoc",
            Redoc.Plug.RedocUI,
            spec_url: "/api/json/open_api"
  end

  # forward "/api/json", DataAggregatorWeb.JsonApiRouter

  # Other scopes may use custom stacks.
  # scope "/api", DataAggregatorWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:data_aggregator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DataAggregatorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
