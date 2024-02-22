defmodule DataAggregatorWeb.CollectionLive.Show do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Collection

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    collection = Collection.get_by_id!(id, load: [:records_count, :digitizing_progress])

    socket =
      socket
      |> assign(:collection, collection)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    assign(socket, :page_title, ~t"Show Collection"m)
  end

  defp apply_action(socket, :import, _params) do
    assign(socket, :page_title, ~t"Import Records"m)
  end

  @impl true
  def handle_info({DataAggregatorWeb.CollectionLive.ImportFormComponent, {:imported, import}}, socket) do
    {:noreply,
     socket
     |> assign(:import, import)
     |> push_navigate(to: ~p"/imports/#{import}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:collections} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        <%= @collection.name %>

        <:actions>
          <.button
            to={~p"/collections"}
            link_type="live_redirect"
            color="secondary"
            icon="hero-arrow-left-mini"
            label={~t"Back to Collections"m}
            responsive
          />
          <.button
            id="import-modal__button"
            to={~p"/collections/#{@collection}/import"}
            link_type="live_patch"
            icon="hero-plus-circle-mini"
            label={~t"Import Records"m}
            responsive
          />
        </:actions>
      </.header>

      <div class="grid justify-items-center">
        <dl class="mt-5 grid grid-cols-2 gap-5 xl:grid-cols-4">
          <.stat_card label={~t"Name"m} stat={@collection.name} />
          <.stat_card label={~t"Owner"m} stat={@collection.owner} />
          <.stat_card label={~t"Type"m} stat="OTHERS" />
          <.stat_card label={~t"Records in Collection"m} stat={@collection.records_count} />
          <.stat_card label={~t"Records Published"m} stat="0" />
          <.stat_card
            label={~t"Digitization Progress"m}
            stat={
              @collection.digitizing_progress
              |> Decimal.from_float()
              |> Decimal.round(1)
            }
            stat_suffix="%"
          />
          <.stat_card label={~t"Expert Reviews"m} stat="0" />
          <.stat_card label={~t"Last Contribution"m} stat="13.11.2023" />
        </dl>
      </div>

      <:portal>
        <.modal
          :if={@live_action == :import}
          id="import-modal"
          on_cancel={JS.patch(~p"/collections/#{@collection}")}
        >
          <.live_component
            module={DataAggregatorWeb.CollectionLive.ImportFormComponent}
            id={"import_form-#{@collection.id}"}
            icon="hero-plus-circle-mini"
            title={@page_title}
            action={:new}
            collection={@collection}
            patch={~p"/collections/#{@collection}"}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end
end
