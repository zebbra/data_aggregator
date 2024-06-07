defmodule DataAggregatorWeb.CollectionLive.Export.Modal do
  @moduledoc """
  This module contains the modal to configure an export for collection.
  """

  use DataAggregatorWeb, :live_component

  alias DataAggregator.Records
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_export() |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id}>
        <.section_heading
          text={~t"Export records"m}
          description={
            mgettext(
              "You are about to export %{row_count} records. Please choose the column headers for your export file and the data layer to be exported.",
              row_count: @export.rows_count
            )
          }
          size="md"
        />
      </.modal_header>

      <.simple_form
        for={@form}
        as={:story}
        id="export_form"
        class="contents"
        phx-target={@myself}
        phx-submit="export:save"
      >
        <div class="h-full space-y-8 overflow-y-auto p-6">
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
          <button type="submit" class="btn btn-primary text-primary-content" disabled={false}>
            <.icon name="hero-arrow-down-tray" />
            <%= ~t"Export"m %>
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
    %{collection: collection, export: export} = socket.assigns

    export =
      export
      |> Export.update!(%{
        header_source: params["header_source"],
        data_layer: params["data_layer"],
        # set the mapping manual, if you want to use
        # custom headers from the current selection
        mapping: nil
      })
      |> Export.enqueue!()

    {
      :noreply,
      socket
      |> assign(:export, export)
      |> push_navigate(to: ~p"/collections/#{collection.id}/exports")
    }
  end

  defp assign_form(socket) do
    assign(socket, :form, %{})
  end

  defp assign_export(socket) do
    %{collection: collection, meta: %{pagify: pagify}} = socket.assigns
    collection = Records.load!(collection, [:records_to_export_query], lazy?: true)

    records_to_export_query =
      Record
      |> Pagify.compile_filters(pagify)
      |> Pagify.merge_filters(collection.records_to_export_query)
      |> Map.get(:filters)

    count_query = Ash.Query.filter_input(Record, records_to_export_query)

    export =
      Export.create!(%{
        name: "export-#{collection.name}-#{:os.system_time()}",
        collection: collection,
        mapping: nil,
        records_query: records_to_export_query,
        rows_count: Records.count!(count_query)
      })

    assign(socket, :export, export)
  end
end
