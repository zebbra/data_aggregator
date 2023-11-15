defmodule DataAggregatorWeb.ImportLive.Confirmation do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Import

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    import = DataAggregator.Records.load!(Import.get_by_id!(id), collection: [:id, :name])

    socket =
      socket
      |> assign(:import, import)
      |> assign(:collection, import.collection)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :confirmation, _params) do
    socket
    |> assign(:page_title, ~t"Confirm the applied mapping"m)
  end

  @impl true
  def handle_event("import:records", _params, socket) do
    case Import.import_records(socket.assigns.import) do
      {:ok, import} ->
        import |> dbg

        {:noreply,
         socket
         |> assign(:import, import)
         |> push_navigate(to: ~p"/imports/#{import}/records")}

      {:error, _error} ->
        {:noreply,
         socket |> put_flash(:error, "Failed to import Records. Check the logs for details.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:imports} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        Confirm your Import for the Collection '<%= @import.collection.name %>'
        <:actions>
          <.button
            to={~p"/imports/#{@import}/mappings"}
            link_type="live_redirect"
            color="secondary"
            icon="hero-arrow-left-mini"
            label={~t"Back to Mapping"m}
            responsive
          />
          <.button
            phx-click="import:records"
            icon="hero-check-mini"
            label={~t"Confirm and import Records"m}
            phx-disable-with={~t"Importing..."m}
            responsive
          />
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <dl class="xl:grid-cols-4 grid grid-cols-2 gap-5 mt-5">
          <.stat_card label={~t"Mapped Columns"m} stat="20 / 30" />
          <.stat_card label={~t"Total Records to Import"m} stat="5444" />
          <.stat_card label={~t"New Records"m} stat="5322" />
          <.stat_card label={~t"Recurring Records"m} stat="122" />
          <.stat_card label={~t"Affected Collection"m} stat={@collection.name} />
          <.stat_card label={~t"Collection Owner"m} stat={@collection.owner} />
          <.stat_card label={~t"Estimated Import Time"m} stat="10" stat_suffix="s" />
          <.stat_card label={~t"Suggested Expert"m} stat="Christophe Praz" />
        </dl>
      </div>
    </.page>
    """
  end
end
