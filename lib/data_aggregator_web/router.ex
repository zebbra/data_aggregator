defmodule DataAggregatorWeb.Router do
  use DataAggregatorWeb, :router

  import PhoenixStorybook.Router
  import DataAggregatorWeb.Locale, only: [assign_current_locale: 2]

  # Browser

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

  scope "/" do
    pipe_through [:locale, :browser]

    scope "/", DataAggregatorWeb do
      pipe_through [:with_root_layout]

      user_hooks = [
        DataAggregatorWeb.LiveLogger,
        DataAggregatorWeb.LiveState,
        DataAggregatorWeb.LiveLocale
      ]

      live_session :default, on_mount: user_hooks do
        live "/", DashboardLive.Index, :index

        live "/records", RecordLive.Index, :index
        live "/records/new", RecordLive.Index, :new
        live "/records/:id/edit", RecordLive.Index, :edit
        live "/records/:id", RecordLive.Show, :show
        live "/records/:id/show/edit", RecordLive.Show, :edit

        live "/collections", CollectionLive.Index, :index
        live "/collections/new", CollectionLive.Index, :new
        live "/collections/:id/edit", CollectionLive.Index, :edit
        live "/collections/:id", CollectionLive.Show, :show
        live "/collections/:id/show/edit", CollectionLive.Show, :edit
        live "/collections/:id/import", CollectionLive.Show, :import

        live "/imports", ImportLive.Index, :index
        live "/imports/:id", ImportLive.Show, :show
        live "/imports/:id/mappings", ImportLive.Show, :mappings
        live "/imports/:id/confirmation", ImportLive.Show, :confirmation
        live "/imports/:id/records", ImportLive.Show, :records
      end
    end
  end

  scope "/api" do
    forward "/", DataAggregatorApi.Router
  end

  # Phoenix Storybook
  scope "/" do
    storybook_assets()

    scope "/", DataAggregatorWeb do
      pipe_through [:locale, :browser]
      live_storybook("/storybook", backend_module: DataAggregatorWeb.Storybook)
    end
  end

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

      live_dashboard "/dashboard",
        metrics: DataAggregatorWeb.Telemetry,
        additional_pages: [
          oban: Oban.LiveDashboard
        ]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
