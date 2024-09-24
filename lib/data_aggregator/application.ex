defmodule DataAggregator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Add logger handlers (eg. Sentry)
    :ok = Logger.add_handlers(:data_aggregator)

    # Enable ecto dev logger (only in dev)
    :ok = Ecto.DevLogger.install(DataAggregator.Repo)

    # Attach default Oban logger
    :ok = Oban.Telemetry.attach_default_logger(encode: false)

    # Make sure AppSignal app is started
    {:ok, _} = Application.ensure_all_started(:appsignal)

    # Appsignal telemetry for LiveView
    Appsignal.Phoenix.LiveView.attach()

    # Send logs to app signal
    Appsignal.Logger.Handler.add("application")

    children = [
      # Start the Telemetry supervisor
      DataAggregatorWeb.Telemetry,
      # Start the Ecto repository
      DataAggregator.Repo,
      # Start the DNS cluster
      {DNSCluster, query: Application.get_env(:data_aggregator, :dns_cluster_query) || :ignore},
      # Start the PubSub system
      DataAggregator.PubSub,
      # Start the Finch HTTP client for sending emails
      {Finch, name: DataAggregator.Finch},
      # Start the Oban queue
      {Oban, Application.fetch_env!(:data_aggregator, Oban)},
      # Start the AshAuthentication system
      {AshAuthentication.Supervisor, otp_app: :data_aggregator},
      # Start the Endpoint (http/https)
      DataAggregatorWeb.Endpoint
    ]

    minimal_children = [
      # Start the Ecto repository
      DataAggregator.Repo,
      # Start the PubSub system
      DataAggregator.PubSub,
      # Start the AshAuthentication system
      {AshAuthentication.Supervisor, otp_app: :data_aggregator}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataAggregator.Supervisor]

    if Application.get_env(:data_aggregator, :minimal) do
      Supervisor.start_link(minimal_children, opts)
    else
      Supervisor.start_link(children, opts)
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DataAggregatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
