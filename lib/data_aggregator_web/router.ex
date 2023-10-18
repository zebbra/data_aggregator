defmodule DataAggregatorWeb.Router do
  use DataAggregatorWeb, :router

  import AshAdmin.Router
  import DataAggregatorWeb.Locale, only: [assign_current_locale: 2]

  pipeline :locale do
    plug :fetch_session

    plug Cldr.Plug.PutLocale,
      apps: [:cldr, :gettext],
      cldr: DataAggregatorWeb.Cldr,
      gettext: DataAggregatorWeb.Gettext,
      from: [:query, :session, :accept_language],
      param: "locale"

    plug :assign_current_locale

    plug Cldr.Plug.PutSession, as: :language_tag
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :with_root_layout do
    plug :put_root_layout, html: {DataAggregatorWeb.Layouts, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug AshGraphql.Plug
  end

  scope "/" do
    pipe_through [:locale, :browser]

    scope "/", DataAggregatorWeb do
      pipe_through [:with_root_layout]

      user_hooks = [
        DataAggregatorWeb.LiveLogger,
        DataAggregatorWeb.LiveState,
        DataAggregatorWeb.LiveLocale,
        DataAggregatorWeb.LiveNavigator
      ]

      live_session :default, on_mount: user_hooks do
        live "/", DashboardLive.Index, :index

        live "/imports", ImportLive.Index, :index
        live "/imports/new", ImportLive.Index, :new
        live "/imports/:id/edit", ImportLive.Index, :edit
        live "/imports/:id", ImportLive.Index, :show
        live "/imports/:id/show/edit", ImportLive.Index, :edit
      end
    end

    # Used by JS hook to update locale from component
    get "/locale", DataAggregatorWeb.LocaleController, :set
  end

  scope "/" do
    pipe_through [:locale, :browser]
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
      pipe_through [:locale, :browser]

      live_dashboard "/dashboard", metrics: DataAggregatorWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
