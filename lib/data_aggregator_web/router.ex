defmodule DataAggregatorWeb.Router do
  use DataAggregatorWeb, :router
  use AshAuthentication.Phoenix.Router

  import DataAggregatorWeb.Locale, only: [assign_current_locale: 2]
  import PhoenixStorybook.Router

  alias AshAuthentication.Phoenix.Overrides.Default
  alias DataAggregator.Accounts.User

  pipeline :locale do
    plug :fetch_session

    plug Cldr.Plug.PutLocale,
      apps: [:cldr, :gettext],
      default: DataAggregatorWeb.Cldr.default_locale(),
      cldr: DataAggregatorWeb.Cldr,
      gettext: DataAggregatorWeb.Gettext,
      from: [],
      param: "locale"

    plug :assign_current_locale

    plug Cldr.Plug.PutSession, as: :language_tag
  end

  # Browser
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :with_root_layout do
    plug :put_root_layout, html: {DataAggregatorWeb.Layouts, :root}
  end

  scope "/", DataAggregatorWeb do
    pipe_through([:locale, :browser, :with_root_layout])

    default_hooks = [
      DataAggregatorWeb.LiveLogger,
      DataAggregatorWeb.LiveLocale,
      Sentry.LiveViewHook,
      {DataAggregatorWeb.LiveUserAuth, :live_user_required},
      {DataAggregatorWeb.LiveUserAuth, :password_set_required},
      {DataAggregatorWeb.LiveUserAuth, :terms_accepted_required}
    ]

    no_password_required_hooks = [
      DataAggregatorWeb.LiveLogger,
      DataAggregatorWeb.LiveLocale,
      Sentry.LiveViewHook,
      {DataAggregatorWeb.LiveUserAuth, :live_user_required}
    ]

    no_terms_required_hooks = [
      DataAggregatorWeb.LiveLogger,
      DataAggregatorWeb.LiveLocale,
      Sentry.LiveViewHook,
      {DataAggregatorWeb.LiveUserAuth, :live_user_required},
      {DataAggregatorWeb.LiveUserAuth, :password_set_required},
      {DataAggregatorWeb.LiveUserAuth, :terms_not_accepted_required}
    ]

    ash_authentication_live_session :no_password_set, on_mount: no_password_required_hooks do
      live "/set_password", AdministrationLive.SetPassword, :index
    end

    ash_authentication_live_session :no_terms_accepted, on_mount: no_terms_required_hooks do
      live "/terms", TermsAndConditionsLive.Index, :index
    end

    ash_authentication_live_session :default, on_mount: default_hooks do
      live "/", DashboardLive.Index, :index

      live "/datasets", CollectionLive.Index, :index
      live "/datasets/:id/records", CollectionLive.Record.Index, :index
      live "/datasets/:id/imports", CollectionLive.Import.Index, :index
      live "/datasets/:id/exports", CollectionLive.Export.Index, :index
      live "/datasets/:id/publications", CollectionLive.Publication.Index, :index
      live "/datasets/:id/image_uploads", CollectionLive.ImageUpload.Index, :index
      live "/datasets/:id/published_records", CollectionLive.PublishedRecords.Index, :index

      @deprecated "is now generated in `DataAggregator.Records.ImageUpload.Changes.CreateUploadLogAfterAction` while mapping images `DataAggregator.Records.ImageUpload.Changes.MapImages`"
      get "/datasets/:id/image_uploads/log/:image_upload_id/download",
          ImageUploadController,
          :download_log
    end

    ash_authentication_live_session :collection_administrator_required,
      on_mount:
        default_hooks ++
          [{DataAggregatorWeb.LiveUserAuth, :live_collection_administrator_required}] do
      live "/administration", AdministrationLive.Index, :index
      live "/administration/new", AdministrationLive.Index, :new
      live "/administration/:user_id/edit", AdministrationLive.Index, :edit

      live "/datasets/new", CollectionLive.Index, :new
      live "/datasets/:id/edit", CollectionLive.Index, :edit
    end

    ash_authentication_live_session :data_digitizer_required,
      on_mount: default_hooks ++ [{DataAggregatorWeb.LiveUserAuth, :live_data_digitizer_required}] do
      live "/datasets/:id/imports/new", CollectionLive.Import.Index, :new
      live "/datasets/:id/imports/:import_id/edit", CollectionLive.Import.Index, :edit
      live "/datasets/:id/imports/:import_id/summary", CollectionLive.Import.Index, :summary
      live "/datasets/:id/image_uploads/new", CollectionLive.ImageUpload.Index, :new

      live "/datasets/:id/image_uploads/:image_upload_id/edit",
           CollectionLive.ImageUpload.Index,
           :edit

      live "/datasets/:id/image_uploads/:image_upload_id/summary",
           CollectionLive.ImageUpload.Index,
           :summary
    end

    # Permanent redirect from old image URL to new image URL
    get "/datasets/:collection_id/image_uploads/images/:image_id",
        ImageUploadController,
        :redirect_to_image

    get "/datasets/:collection_id/image_uploads/images/:image_id/image.jpg",
        ImageUploadController,
        :show_image

    auth_routes(AuthController, User, path: "/auth")
    sign_out_route AuthController

    sign_in_route(
      register_path: "/register",
      on_mount: [{DataAggregatorWeb.LiveUserAuth, :live_no_user}],
      overrides: [
        DataAggregatorWeb.AuthOverrides,
        Default
      ],
      auth_routes_prefix: "/auth"
    )

    reset_route overrides: [
                  DataAggregatorWeb.AuthOverrides,
                  Default
                ]
  end

  scope "/api" do
    forward "/", DataAggregatorApi.Router
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:data_aggregator, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    # Phoenix Storybook
    import PhoenixStorybook.Router

    scope "/" do
      storybook_assets()

      scope "/", DataAggregatorWeb do
        pipe_through [:locale, :browser]
        live_storybook("/storybook", backend_module: DataAggregatorWeb.Storybook)
      end
    end

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
