defmodule DataAggregatorWeb.ValidationResponseLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.ValidationResponse

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, selected_validation_response: nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_validation_responses(params, get_actor(socket)) do
      {:ok, {validation_responses, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, validation_responses, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/validation_responses")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="validation_responses"
      current_user={@current_user}
      open={@selected_validation_response != nil}
    >
      <.page_header class="px-6 pt-1 pb-4 md:py-6 lg:px-8">
        {~t"Validation Responses"m}
        <:actions>
          <.link patch={~p"/validation_responses/new"} class="btn btn-primary max-sm:btn-sm">
            <.icon name="hero-plus" class="max-sm:size-4" />
            <span class="max-sm:hidden">{~t"Add Validation Response"m}</span>
            <span class="sm:hidden">{~t"Add"m}</span>
          </.link>
        </:actions>
      </.page_header>
      <.table
        opts={[
          container_attrs: [
            class: "overflow-x-auto pb-4"
          ],
          no_results_content: no_results_content()
        ]}
        path={~p"/validation_responses"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, validation_response} ->
            JS.push("validation_response:select", value: %{id: validation_response.id})
          end
        }
      >
        <:col :let={{_id, validation_response}} field={:id} label={~t"ID"m}>
          {validation_response.id}
        </:col>
        <:col :let={{_id, validation_response}} field={:type} label={~t"Type"m}>
          <.badge color="blue" class="mt-0.5">
            <span class="px-1.5">{validation_response.type}</span>
          </.badge>
        </:col>
        <:col :let={{_id, validation_response}} field={:state} label={~t"State"m}>
          <.badge color={state_color(validation_response.state)} class="mt-0.5">
            <span class="px-1.5">{validation_response.state}</span>
          </.badge>
        </:col>
        <:col :let={{_id, validation_response}} field={:rows_count} label={~t"Total Rows"m}>
          {validation_response.rows_count || 0}
        </:col>
        <:col :let={{_id, validation_response}} field={:rows_validated_count} label={~t"Validated"m}>
          {validation_response.rows_validated_count || 0}
        </:col>
        <:col :let={{_id, validation_response}} field={:rows_invalid_count} label={~t"Invalid"m}>
          {validation_response.rows_invalid_count || 0}
        </:col>
        <:col :let={{_id, validation_response}} field={:rows_error_count} label={~t"Errors"m}>
          {validation_response.rows_error_count || 0}
        </:col>
        <:col :let={{_id, validation_response}} field={:inserted_at} label={~t"Created"m}>
          {Calendar.strftime(validation_response.inserted_at, "%Y-%m-%d %H:%M")}
        </:col>
      </.table>
      <.pagination meta={@meta} path={~p"/validation_responses"} />
      <:secondary>
        <.slideover
          title={validation_response_title(@selected_validation_response)}
          open={@selected_validation_response != nil}
          on_cancel={JS.push("validation_response:select", value: %{id: nil})}
          size="xl"
        >
          <.list :if={@selected_validation_response}>
            <:item title={~t"ID"m}>
              {@selected_validation_response.id}
            </:item>
            <:item title={~t"Type"m}>
              <.badge color="blue" class="mt-0.5">
                <span class="px-1.5">{@selected_validation_response.type}</span>
              </.badge>
            </:item>
            <:item title={~t"State"m}>
              <.badge color={state_color(@selected_validation_response.state)} class="mt-0.5">
                <span class="px-1.5">{@selected_validation_response.state}</span>
              </.badge>
            </:item>
            <:item title={~t"Row Counts"m}>
              <div class="space-y-1">
                <div>Total: {@selected_validation_response.rows_count || 0}</div>
                <div>Validated: {@selected_validation_response.rows_validated_count || 0}</div>
                <div>Invalid: {@selected_validation_response.rows_invalid_count || 0}</div>
                <div>Errors: {@selected_validation_response.rows_error_count || 0}</div>
              </div>
            </:item>
            <:item title={~t"Timestamps"m}>
              <div class="space-y-1">
                <div>
                  Created: {Calendar.strftime(
                    @selected_validation_response.inserted_at,
                    "%Y-%m-%d %H:%M:%S"
                  )}
                </div>
                <div :if={@selected_validation_response.started_at}>
                  Started: {Calendar.strftime(
                    @selected_validation_response.started_at,
                    "%Y-%m-%d %H:%M:%S"
                  )}
                </div>
                <div :if={@selected_validation_response.finished_at}>
                  Finished: {Calendar.strftime(
                    @selected_validation_response.finished_at,
                    "%Y-%m-%d %H:%M:%S"
                  )}
                </div>
              </div>
            </:item>
          </.list>
        </.slideover>
      </:secondary>
      <:portal>
        <.modal
          id="validation_response_modal"
          show={@live_action in [:new, :summary]}
          size="3xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(~p"/validation_responses")}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :summary]}
            module={DataAggregatorWeb.ValidationResponseLive.FormComponent}
            id={@validation_response.id || :new}
            action={@live_action}
            validation_response={@validation_response}
            current_user={@current_user}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("validation_response:select", %{"id" => nil}, socket) do
    {:noreply, assign(socket, :selected_validation_response, nil)}
  end

  @impl true
  def handle_event("validation_response:select", %{"id" => id}, socket) do
    validation_response = get_validation_response(id, get_actor(socket))

    {:noreply, assign(socket, :selected_validation_response, validation_response)}
  end

  @impl true
  def handle_event("save", %{"file_url" => file_url, "type" => type}, socket) do
    # TODO: Implement actual validation response creation logic
    {:noreply,
     socket
     |> put_flash(
       :info,
       "Validation response creation not yet implemented. File URL: #{file_url}, Type: #{type}"
     )
     |> push_patch(to: ~p"/validation_responses")}
  end

  defp validation_response_title(nil), do: ""

  defp validation_response_title(validation_response), do: "Validation Response #{validation_response.id}"

  defp get_validation_response(id, actor) do
    ValidationResponse.get_by_id!(id, actor: actor)
  end

  defp state_color(state) do
    case state do
      :pending -> "yellow"
      :queued -> "blue"
      :running -> "purple"
      :done -> "green"
      :failed -> "red"
      _ -> "gray"
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Validation Responses"m)
    |> assign(:validation_response, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Validation Response"m)
    |> assign(:validation_response, %ValidationResponse{})
  end

  defp apply_action(socket, :summary, %{"id" => id}) do
    validation_response = ValidationResponse.get_by_id!(id, actor: get_actor(socket))

    socket
    |> assign(:page_title, ~t"Validation Response Summary"m)
    |> assign(:validation_response, validation_response)
  end

  defp list_validation_responses(params, actor, opts \\ []) do
    opts = Keyword.put(opts, :actor, actor)
    AshPagify.validate_and_run(ValidationResponse, params, opts)
  end

  def no_results_content(assigns \\ %{}) do
    ~H"""
    <.empty_state
      title={~t"No Validation Responses"m}
      description={~t"No validation responses have been created yet."m}
      icon="hero-squares-2x2"
    />
    """
  end
end
