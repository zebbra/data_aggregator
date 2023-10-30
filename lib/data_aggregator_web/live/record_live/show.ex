defmodule DataAggregatorWeb.RecordLive.Show do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Data.Record

  import DataAggregatorWeb.QueryBuilder

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
    <main>
      <.header class="top-16 sticky">
        <%= @record.scientificName %>

        <:actions>
          <.styled_link
            patch={~p"/records/#{@record}/show/edit?#{@current_path_params}"}
            id="record-modal__button"
          >
            <.icon name="hero-pencil-square-mini" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <span class="sm:inline-block hidden"><%= ~t"Edit Record"m %></span>
          </.styled_link>
        </:actions>
      </.header>

      <.back navigate={~p"/records?#{@current_path_params}"}>
        <%= ~t"Back"m %>
      </.back>

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
    </main>
    """
  end
end
