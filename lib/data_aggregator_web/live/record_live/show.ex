defmodule DataAggregatorWeb.RecordLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Records.Record

  import DataAggregatorWeb.Components.Internal.Path, only: [assign_current_path_params: 2]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    record = Record.get_by_id!(id)

    socket =
      socket
      |> assign(:record, record)
      |> assign_current_path_params(params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, ~t"Show Record"m)
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, ~t"Edit Record"m)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page active_link={:records} environment={@environment} sidebar_nav={@sidebar_nav}>
      <.header class="top-16 sticky">
        <%= @record.tax_scientific_name %>

        <:actions>
          <.button
            to={~p"/records?#{@current_path_params}"}
            link_type="live_redirect"
            color="secondary"
            icon="hero-arrow-left-mini"
            label={~t"Back to Records"m}
            responsive
          />
          <.button
            id="record-modal__button"
            to={~p"/records/#{@record}/show/edit?#{@current_path_params}"}
            link_type="live_patch"
            icon="hero-pencil-square-mini"
            label={~t"Edit Record"m}
            responsive
          />
        </:actions>
      </.header>

      <:portal>
        <.modal
          :if={@live_action in [:new, :edit]}
          id="record-modal"
          on_cancel={JS.patch(~p"/records/#{@record}?#{@current_path_params}")}
        >
          <.live_component
            module={DataAggregatorWeb.RecordLive.FormComponent}
            id={@record.id}
            icon="hero-plus-circle-mini"
            title={@page_title}
            action={@live_action}
            record={@record}
            patch={~p"/records/#{@record}?#{@current_path_params}"}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end
end
