defmodule DataAggregatorWeb.DashboardLive.Index do
  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Headless.StatCard

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:dashboard} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header>Dashboard</.header>
      <div class="justify-items-center grid">
        <dl class="xl:grid-cols-4 sm:grid-cols-2 grid grid-cols-1 gap-5 mt-5">
          <.stat_card label={~t"Amount of Collections"m} stat="7" />
          <.stat_card label={~t"Total Records"m} stat="10433" />
          <.stat_card label={~t"Digitization Progress"m} stat="74%" />
          <.stat_card label={~t"Records Published"m} stat="3072" />
          <.stat_card label={~t"Records Reviewed"m} stat="1207" />
          <.stat_card label={~t"Last Contribution"m} stat="13.11.2013" />
          <.stat_card label={~t"Open Reviews"m} stat="27" />
          <.stat_card label={~t"Contributors"m} stat="87" />
        </dl>
      </div>
    </.page>
    """
  end

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
  end
end
