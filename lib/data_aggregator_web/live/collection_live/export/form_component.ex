defmodule DataAggregatorWeb.CollectionLive.Export.FormComponent do
  @moduledoc """
  This module contains the modal form component to configure an export for collection.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [filter_map: 3]

  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_rows_count() |> assign_form()}
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
          <p class="text-sm">
            <%= mgettext(
              "You are about to export %{rows_count} records. Please choose the column headers for your export file and the data layer to be exported.",
              rows_count: format_number(@rows_count)
            ) %>
          </p>
          <section class="border-black-white/25 flex flex-col rounded-lg border border-dashed p-6">
            <.fieldset legend={~t"Select your data headers"m}>
              <.fieldgroup class="space-y-3">
                <.field
                  field={@form[:header_source]}
                  name="header_source"
                  id="header_source_1"
                  label="Collection Mapping"
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
                  description="The exported data will be the same as the original collection data"
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
              </.fieldgroup>
            </.fieldset>
          </section>

          <p class="text-base-content/60 mt-1 text-sm">
            * <%= ~t"required to choose an option"m %>
          </p>
        </div>

        <:actions modal>
          <button type="submit" class="btn btn-primary text-primary-content" disabled={@busy}>
            <%= ~t"Start export"m %>
          </button>
          <button type="button" class="btn btn-ghost" onclick="export_modal.close()">
            <%= ~t"Cancel"m %>
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
         |> push_navigate(to: ~p"/collections/#{collection_id}/exports")}

      {:error, _} ->
        {
          :noreply,
          socket
          |> put_flash(:error, ~t"An export for this collection is already in process"m)
          |> push_navigate(to: ~p"/collections/#{collection_id}/exports")
        }
    end
  end

  defp create_and_enqueue(socket, params) do
    %{
      collection: collection,
      meta: %{ash_pagify: ash_pagify},
      rows_count: rows_count,
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

  defp assign_rows_count(socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}, layer: layer} = socket.assigns
    collection = Ash.load!(collection, [:records_to_export_query], lazy?: true)

    records_to_export_query = filter_map(ash_pagify, collection.records_to_export_query, layer)

    count_query =
      Record
      |> AshPagify.query_for_filters_map(records_to_export_query)
      |> Ash.Query.set_tenant(collection)

    rows_count = Ash.count!(count_query)

    assign(socket, :rows_count, rows_count)
  end
end
