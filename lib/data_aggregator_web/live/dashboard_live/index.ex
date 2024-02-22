defmodule DataAggregatorWeb.DashboardLive.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Record

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Dashboard"m)
    |> assign(:record, nil)
    |> assign(:collections_count, collections_count())
    |> assign(:records_count, records_count())
  end

  defp collections_count do
    Records.count!(Collection)
  end

  defp records_count do
    Records.count!(Record)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:dashboard} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header>Dashboard</.header>
      <div class="grid justify-items-center">
        <dl class="mt-5 grid grid-cols-2 gap-5 sm:grid-cols-2 xl:grid-cols-4">
          <.dashboard_stat
            title={~t"Amount of Collections"m}
            value={format_number(@collections_count)}
          />
          <.dashboard_stat title={~t"Total Records"m} value={format_number(@records_count)} />
          <.dashboard_stat title={~t"Digitization Progress"m} value="74%" />
          <.dashboard_stat title={~t"Records Published"m} value="3072" />
          <.dashboard_stat title={~t"Records Reviewed"m} value="1207" />
          <.dashboard_stat title={~t"Last Contribution"m} value="13.11.2013" />
          <.dashboard_stat title={~t"Open Reviews"m} value="27" />
          <.dashboard_stat title={~t"Contributors"m} value="87" />
        </dl>
      </div>
    </.page>
    """
  end

  attr :title, :string
  attr :value, :string

  defp dashboard_stat(assigns) do
    ~H"""
    <div class="stats shadow ">
      <div class="stat">
        <div class="stat-title text-sm"><%= @title %></div>
        <div class="stat-value font-semibold"><%= @value %></div>
      </div>
    </div>
    """
  end
end
