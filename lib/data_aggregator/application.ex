defmodule DataAggregator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Add logger handlers (eg. Sentry)
    :ok = Logger.add_handlers(:data_aggregator)

    children = [
      # Start the Telemetry supervisor
      DataAggregatorWeb.Telemetry,
      # Start the Ecto repository
      DataAggregator.Repo,
      # Start the DNS cluster
      {DNSCluster, query: Application.get_env(:data_aggregator, :dns_cluster_query) || :ignore},
      # Start the PubSub system
      {Phoenix.PubSub, name: DataAggregator.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DataAggregator.Finch},
      # Start a worker by calling: DataAggregator.Worker.start_link(arg)
      # {DataAggregator.Worker, arg},
      # Start the Endpoint (http/https)
      DataAggregatorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataAggregator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DataAggregatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
