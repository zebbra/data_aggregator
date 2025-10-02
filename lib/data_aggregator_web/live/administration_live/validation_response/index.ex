defmodule DataAggregatorWeb.AdministrationLive.ValidationResponse.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view
  use DataAggregatorWeb.AdministrationLive.ValidationResponse.Subscriptions

  import DataAggregatorWeb.AdministrationLive.ValidationResponse.Components,
    only: [validation_response_state_badge: 1, validation_response_type_badge: 1]

  import DataAggregatorWeb.AdministrationLive.ValidationResponse.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.ValidationResponse

  @load load()

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, selected_validation_response: nil)

    {:ok, subscribe_for_validation_response_updates(socket, connected?(socket))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case list_validation_responses(params, get_actor(socket)) do
      {:ok, {validation_responses, meta}} ->
        socket
        |> assign(meta: meta)
        |> assign(show_error_log_preview: false)
        |> stream(:results, validation_responses, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/administration/validation_responses")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page
      current="administration"
      current_user={@current_user}
      open={@selected_validation_response != nil}
    >
      <.page_header class="px-6 pt-1 pb-4 md:py-6 lg:px-8">
        {~t"Validation Imports"m}
        <:actions>
          <.link
            patch={~p"/administration/validation_responses/new"}
            class="btn btn-primary max-sm:btn-sm"
          >
            <.icon name="hero-plus" class="max-sm:size-4" />
            <span class="max-sm:hidden">{~t"Import validation data"m}</span>
            <span class="sm:hidden">{~t"Add"m}</span>
          </.link>
        </:actions>
      </.page_header>
      <.secondary_navigation class="top-[calc(4rem-1px)] sticky">
        <.secondary_navigation_item href={~p"/administration/users"} label={~t"Users"m} />
        <.secondary_navigation_item
          href={~p"/administration/validation_responses"}
          label={~t"Validation Imports"m}
          active
        />
      </.secondary_navigation>
      <.table
        opts={[
          container_attrs: [
            class: "overflow-x-auto pb-4"
          ],
          no_results_content: no_results_content()
        ]}
        path={~p"/administration/validation_responses"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, validation_response} ->
            JS.push("validation_response:select", value: %{id: validation_response.id})
          end
        }
      >
        <:col :let={{_id, validation_response}} field={:state} label={~t"State"m}>
          <.validation_response_state_badge validation_response={validation_response} />
        </:col>
        <:col :let={{_id, validation_response}} field={:type} label={~t"Type"m}>
          <.validation_response_type_badge type={validation_response.type} />
        </:col>
        <:col :let={{_id, validation_response}} label={~t"File"m}>
          <.file_info show_rows={false} attachment={validation_response.attachment} />
        </:col>
        <:col :let={{_id, validation_response}} label={~t"Size"m}>
          <.attachment_download_badge attachment={validation_response.attachment} />
        </:col>
        <:col :let={{_id, validation_response}} field={:inserted_at} label={~t"Created at"m}>
          {format_datetime(validation_response.inserted_at, format: :short)}
        </:col>
        <:col :let={{_id, validation_response}} field={:created_by} label={~t"Created by"m}>
          {maybe_set_user(validation_response.created_by)}
        </:col>
        <:col :let={{_id, validation_response}} field={:started_at} label={~t"Started at"m}>
          {format_datetime(validation_response.started_at, format: :short)}
          <div :if={validation_response.duration} class="text-base-content/60 text-xs">
            {validation_response.duration}
          </div>
        </:col>
        <:col :let={{_id, validation_response}} field={:started_by} label={~t"Started by"m}>
          {maybe_set_user(validation_response.started_by)}
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
        <:action
          :let={{_id, validation_response}}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <.table_action_button
            :if={can_edit?(validation_response)}
            patch={
              build_path(
                ~p"/administration/validation_responses/#{validation_response.id}/summary",
                @meta
              )
            }
            data-tip={~t"summary"m}
            icon="hero-pencil-square-mini"
          />
          <.table_action_button
            :if={can_rerun?(validation_response)}
            patch={
              build_path(
                ~p"/administration/validation_responses/#{validation_response.id}/summary",
                @meta
              )
            }
            data-tip={~t"Rerun import"m}
            icon="hero-arrow-path"
          />
          <.table_action_button
            :if={validation_response.state in [:running]}
            phx-click="validation_response:cancel"
            phx-value-id={validation_response.id}
            data-tip={~t"Cancel import"m}
            icon="hero-x-mark"
          />
          <.table_action_button
            phx-click={JS.push("validation_response:delete", value: %{id: validation_response.id})}
            data-tip={~t"Delete import"m}
            icon="hero-trash"
            class="text-error hover:bg-error/10"
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_validation_response_alert"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/administration/validation_responses"} />
      <:secondary>
        <.slideover
          title={~t"Show validation import details"m}
          open={@selected_validation_response != nil}
          on_cancel={JS.push("validation_response:select", value: %{id: nil})}
          size="xl"
        >
          <.section_heading
            text={~t"Validation Import"m}
            class="border-black-white/10 border-b px-6 pb-6 lg:px-8"
            align_items="baseline"
            size="md"
          >
            <:actions>
              <div class="mt-1 flex items-center gap-x-2">
                <span class="text-sm">{~t"State:"m}</span>
                <.validation_response_state_badge validation_response={@selected_validation_response} />
              </div>
            </:actions>
          </.section_heading>
          <.list :if={@selected_validation_response}>
            <:item title={~t"File"m}>
              <.file_info
                show_rows={false}
                attachment={@selected_validation_response.attachment}
                badge
              />
            </:item>
            <:item title={~t"Created by"m}>
              {maybe_set_user(@selected_validation_response.created_by)}
            </:item>
            <:item title={~t"Created at"m}>
              {format_datetime(@selected_validation_response.inserted_at)}
            </:item>
            <:item title={~t"Type"m}>
              <.validation_response_type_badge type={@selected_validation_response.type} />
            </:item>
            <:item title={~t"Total Rows"}>
              {@selected_validation_response.rows_count || 0}
            </:item>
            <:item title={~t"Progress"m}>
              <div class="flex flex-col">
                <.progress
                  value={@selected_validation_response.validation_progress}
                  max={1}
                  class="progress progress-primary w-full"
                />
                <div>
                  {format_number(@selected_validation_response.rows_validated_count)} / {format_number(
                    @selected_validation_response.rows_count
                  )} {~t"rows"m}
                </div>
                <div
                  :if={@selected_validation_response.rows_invalid_count not in [0, nil]}
                  class="text-error"
                >
                  {~t"invalid rows:"m} {format_number(
                    @selected_validation_response.rows_invalid_count
                  )}
                </div>
              </div>
            </:item>
            <:item title={~t"Error Log"m}>
              <div class="flex flex-col">
                <div :if={@selected_validation_response.rows_invalid_count not in [0, nil]}>
                  <div class="text-error">
                    {~t"detected errors:"m} {format_number(
                      @selected_validation_response.rows_error_count
                    )}
                  </div>
                  <div class="inline-flex gap-1">
                    <.link
                      data-tip={~t"Preview error log"m}
                      class="tooltip gap-x-1 self-center rounded-full bg-blue-100 px-1.5 pb-0.5 text-xs font-medium text-blue-500 opacity-75 hover:opacity-100"
                      phx-click="show:error_log_preview"
                      aria-label={~t"Open error log preview"m}
                    >
                      <.icon name="hero-eye-mini" class="size-3 shrink-0" />
                    </.link>
                    <div class="tooltip flex h-10 self-center" data-tip={~t"Download error log"}>
                      <.file_info
                        show_file_name={false}
                        attachment={@selected_validation_response.error_log}
                        rows={@selected_validation_response.rows_error_count}
                      />
                    </div>
                  </div>
                </div>
                <div
                  :if={@selected_validation_response.rows_invalid_count in [0, nil]}
                  class="text-italic"
                >
                  <%= if @selected_validation_response.state == :failed do %>
                    <div class="text-error">
                      {~t"An unknown error occurred"m}
                    </div>
                  <% else %>
                    {~t"No errors found"m}
                  <% end %>
                </div>
              </div>
            </:item>
            <:item title={~t"Started by"m}>
              {maybe_set_user(@selected_validation_response.started_by)}
            </:item>
            <:item title={~t"Started at"m}>
              <div :if={@selected_validation_response.finished_at == nil}>
                {format_datetime(@selected_validation_response.started_at)}
              </div>
              <div :if={@selected_validation_response.finished_at != nil}>
                {format_date_interval(
                  @selected_validation_response.started_at,
                  @selected_validation_response.finished_at
                )}
              </div>
              {@selected_validation_response.duration}
            </:item>
          </.list>
        </.slideover>
      </:secondary>
      <:portal>
        <.modal
          :if={
            @selected_validation_response != nil and @selected_validation_response.error_log != nil
          }
          id="import_error_log_preview_modal"
          show={@show_error_log_preview}
          title={~t"Import Errors"}
          responsive
          on_cancel={JS.push("hide:error_log_preview")}
          size="5xl"
        >
          <.table
            opts={[
              container_attrs: [
                class: "overflow-x-auto -mx-6 lg:-mx-8"
              ]
            ]}
            items={error_log_preview_data(@selected_validation_response.error_log)}
          >
            <:col :let={error} label={~t"Catalog Number"m}>
              {error[:catalogNumber]}
            </:col>
            <:col :let={error} label={~t"Scientific Name"m}>
              {error[:scientificName]}
            </:col>
            <:col :let={error} label={~t"Field"}>
              {error[:field]}
            </:col>
            <:col :let={error} label={~t"Value"}>
              {error[:value]}
            </:col>
            <:col :let={error} label={~t"Error message"} class="text-right">
              {error[:message]}
            </:col>
          </.table>

          <:footer reverse={false}>
            <div class="inline-flex gap-2 py-2">
              <.attachment_download_badge attachment={@selected_validation_response.error_log} />
              <span class="text-base/6 self-center text-xs italic">
                {~t"Only the first 100 rows will be shown. Download the file to have the complete log"}
              </span>
            </div>
          </:footer>
        </.modal>

        <.modal
          id="validation_response_modal"
          show={@live_action in [:new, :summary]}
          size="3xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(~p"/administration/validation_responses")}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :summary]}
            module={DataAggregatorWeb.AdministrationLive.ValidationResponse.FormComponent}
            id={@validation_response.id || :new}
            action={@live_action}
            validation_response={@validation_response}
            current_user={@current_user}
          />
        </.modal>
        <.alert
          id="confirm_validation_response_alert"
          size="md"
          title={~t"Are you sure you want to delete this validation import?"m}
          confirm_button_label={~t"Yes, delete validation import"m}
        >
          <p class="mt-2 text-sm">
            {~t"This will delete the validation import and attached files."m}
          </p>
        </.alert>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("show:error_log_preview", _, socket) do
    {:noreply, assign(socket, :show_error_log_preview, true)}
  end

  @impl true
  def handle_event("hide:error_log_preview", _, socket) do
    {:noreply, assign(socket, :show_error_log_preview, false)}
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
  def handle_event("validation_response:cancel", %{"id" => id}, socket) do
    validation_response = get_validation_response(id, get_actor(socket))

    case ValidationResponse.set_cancelled(validation_response, actor: get_actor(socket)) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, ~t"Validation import canceled successfully"m)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"Failed to cancel validation import"m)}
    end
  end

  @impl true
  def handle_event("validation_response:delete", %{"id" => id}, socket) do
    validation_response = get_validation_response(id, get_actor(socket))

    case ValidationResponse.destroy(validation_response, actor: get_actor(socket)) do
      :ok ->
        {:noreply, put_flash(socket, :info, ~t"Validation import deleted successfully"m)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"Failed to delete validation import"m)}
    end
  end

  defp get_validation_response(id, actor) do
    ValidationResponse.get_by_id!(id, actor: actor, load: @load)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, ~t"Validation Imports"m)
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
    opts = opts |> Keyword.put(:actor, actor) |> Keyword.put(:load, @load)
    AshPagify.validate_and_run(ValidationResponse, params, opts)
  end

  defp error_log_preview_data(error_log) do
    error_log = Ash.load!(error_log, [:url], lazy?: true)

    case Explorer.DataFrame.from_csv(error_log.url, max_rows: 100) do
      {:ok, df} ->
        Explorer.DataFrame.to_rows(df, atom_keys: true)

      {:error, _} ->
        # :error happens if the csv file is empty, so we return an empty list
        []
    end
  end

  def no_results_content(assigns \\ %{}) do
    ~H"""
    <.empty_state
      title={~t"No Validation Imports"m}
      description={~t"No Validation Imports have been created yet."m}
      icon="hero-squares-2x2"
    />
    """
  end
end
