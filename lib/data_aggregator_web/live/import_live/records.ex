defmodule DataAggregatorWeb.ImportLive.Records do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Import

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    import = DataAggregator.Records.load!(Import.get_by_id!(id), [:records_count, :collection])

    socket =
      socket
      |> assign(:import, import)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show_records, _params) do
    socket
    |> put_flash(:info, "#{socket.assigns.import.records_count} Records imported successfully.")
    |> assign(:page_title, ~t"Imported Records"m)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:imports} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        The following records were imported to your collection '<%= @import.collection.name %>'
        <:actions>
          <.button
            to={~p"/imports"}
            link_type="live_redirect"
            color="secondary"
            icon="hero-arrow-left-mini"
            label={~t"Back to Imports"m}
            responsive
          />
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <dl class="grid grid-cols-2 gap-5 mt-5">
          <.stat_card label={~t"New Imported"m} stat="764" />
          <.stat_card label={~t"Updated"m} stat="196" />
        </dl>
      </div>
    </.page>
    """
  end
end
