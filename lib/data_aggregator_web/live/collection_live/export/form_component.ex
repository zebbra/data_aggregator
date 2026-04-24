defmodule DataAggregatorWeb.CollectionLive.Export.FormComponent do
  @moduledoc """
  This module contains the modal form component to configure an export for collection.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [filter_map: 3]

  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Record
  alias Phoenix.LiveView.AsyncResult

  require Logger

  @impl true
  def update(assigns, socket) do
    first_update? = not Map.has_key?(socket.assigns, :rows_count)

    socket = socket |> assign(assigns) |> assign_form()

    socket =
      if first_update? do
        socket
        |> assign(:rows_count, AsyncResult.loading())
        |> start_async_rows_count()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title={~t"Export records"m} />
      <.simple_form
        for={@form}
        as={:story}
        id="export_form"
        class="contents"
        phx-target={@myself}
        phx-submit="export:save"
      >
        <div class="h-full space-y-8 overflow-y-auto p-6">
          <.async_data :let={rows_count} async_result={@rows_count}>
            <:loading>
              <.skeleton class="h-4 w-full" />
              <.skeleton class="mt-2 h-4 w-4/5" />
            </:loading>
            <:failed>
              <div class="flex">
                <div class="mr-4 shrink-0">
                  <.icon name="hero-x-circle-mini" class="size-6 text-error" />
                </div>
                <p class="text-sm">
                  {~t"Failed to load the export summary. Please close the modal and try again."m}
                </p>
              </div>
            </:failed>
            <p class="text-sm">
              {mgettext(
                "You are about to export %{rows_count} records. Please choose the column headers for your export file and the data layer to be exported.",
                rows_count: format_number(rows_count)
              )}
            </p>
          </.async_data>
          <section class="border-black-white/25 flex flex-col rounded-lg border border-dashed p-6">
            <.fieldset legend={~t"Select your data headers"m}>
              <.fieldgroup class="space-y-3">
                <.field
                  field={@form[:header_source]}
                  name="header_source"
                  id="header_source_1"
                  label="Dataset Mapping"
                  description="The column headers will be based on the last file you uploaded"
                  type="radio"
                  required
                  checked={true}
                  value="collection_mapping"
                />
                <.field
                  field={@form[:header_source]}
                  name="header_source"
                  id="header_source_2"
                  label="DWC Attributes"
                  description="The Darwin Core attributes will be used as column headers"
                  type="radio"
                  required
                  value="dwc_attributes"
                />
              </.fieldgroup>
            </.fieldset>
          </section>

          <section class="border-black-white/25 flex flex-col rounded-lg border border-dashed p-6">
            <.fieldset legend={~t"Select the data layer to be exported"m}>
              <.fieldgroup class="space-y-3">
                <.field
                  field={@form[:data_layer]}
                  name="data_layer"
                  id="data_layer_1"
                  label="Raw"
                  description="The exported data will be the same as the original dataset data"
                  type="radio"
                  required
                  checked={true}
                  value="raw"
                />
                <.field
                  field={@form[:data_layer]}
                  name="data_layer"
                  id="data_layer_2"
                  label="Encoded"
                  description="Exported data will consist of enriched data from various thesauri and vocabularies"
                  type="radio"
                  required
                  value="encoded"
                />
                <.field
                  field={@form[:data_layer]}
                  name="data_layer"
                  id="data_layer_3"
                  label="Validated"
                  description="Exported data will consist of validated data."
                  type="radio"
                  required
                  value="validated"
                />
              </.fieldgroup>
            </.fieldset>
          </section>

          <p class="text-base-content/60 mt-1 text-sm">
            * {~t"required to choose an option"m}
          </p>
        </div>

        <:actions modal>
          <button
            type="submit"
            class="btn btn-primary text-primary-content"
            disabled={@busy or not @rows_count.ok?}
          >
            {~t"Start export"m}
          </button>
          <button type="button" class="btn btn-ghost" onclick="export_modal.close()">
            {~t"Cancel"m}
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("export:save", params, socket) do
    %{collection: %{id: collection_id}} = socket.assigns

    case create_and_enqueue(socket, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, ~t"Export started in background"m)
         |> push_navigate(to: ~p"/datasets/#{collection_id}/exports")}

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(:error, ~t"An export for this dataset is already in process"m)
          |> push_navigate(to: ~p"/datasets/#{collection_id}/exports")
        }
    end
  end

  defp create_and_enqueue(socket, params) do
    %{
      collection: collection,
      meta: %{ash_pagify: ash_pagify},
      rows_count: %AsyncResult{result: rows_count},
      layer: layer
    } =
      socket.assigns

    collection = Ash.load!(collection, [:records_to_export_query], lazy?: true)
    actor = get_actor(socket)
    records_to_export_query = filter_map(ash_pagify, collection.records_to_export_query, layer)

    %{
      name: "export-#{collection.name}-#{:os.system_time()}",
      collection: collection,
      mapping: nil,
      records_query: records_to_export_query,
      rows_count: rows_count,
      header_source: params["header_source"],
      data_layer: params["data_layer"]
    }
    |> Export.create!(tenant: collection)
    |> Export.enqueue(%{started_by_id: actor.id})
  end

  defp assign_form(socket) do
    assign(socket, :form, %{})
  end

  defp start_async_rows_count(socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}, layer: layer} = socket.assigns
    actor = get_actor(socket)

    assign_async(socket, :rows_count, fn ->
      load_rows_count(collection, ash_pagify, layer, actor)
    end)
  end

  defp load_rows_count(collection, ash_pagify, layer, actor) do
    collection = Ash.load!(collection, [:records_to_export_query], lazy?: true, actor: actor)
    records_to_export_query = filter_map(ash_pagify, collection.records_to_export_query, layer)

    rows_count =
      Record
      |> AshPagify.query_for_filters_map(records_to_export_query)
      |> Ash.Query.set_tenant(collection)
      |> Ash.count!(actor: actor)

    {:ok, %{rows_count: rows_count}}
  end
end
