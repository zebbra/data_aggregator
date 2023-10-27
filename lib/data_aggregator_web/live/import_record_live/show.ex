defmodule DataAggregatorWeb.ImportRecordLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Imports.ImportRecord

  import DataAggregatorWeb.QueryBuilder

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    import_record = ImportRecord.get_by_id!(id)

    socket =
      socket
      |> assign(:import_record, import_record)
      |> assign_current_path_params(params)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, ~t"Show Import Record"m)
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, ~t"Edit Import Record"m)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <.header class="sticky top-16">
        <%= @import_record.unique_qualifier %>

        <:actions>
          <.styled_link
            patch={~p"/import_records/#{@import_record}/show/edit?#{@current_path_params}"}
            id="import-record-modal__button"
          >
            <.icon name="hero-pencil-square-mini" class="-ml-0.5 mr-1.5 h-5 w-5" />
            <span class="sm:inline-block hidden"><%= ~t"Edit Import Record"m %></span>
          </.styled_link>
        </:actions>
      </.header>

      <.back navigate={~p"/import_records?#{@current_path_params}"}>
        <%= ~t"Back"m %>
      </.back>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="import-record-modal"
        on_cancel={JS.patch(~p"/import_records/#{@import_record}?#{@current_path_params}")}
      >
        <.live_component
          module={DataAggregatorWeb.ImportRecordLive.FormComponent}
          id={@import_record.id}
          icon="hero-plus-circle-mini"
          title={@page_title}
          action={@live_action}
          import_record={@import_record}
          patch={~p"/import_records/#{@import_record}?#{@current_path_params}"}
        />
      </.modal>
    </main>
    """
  end
end
