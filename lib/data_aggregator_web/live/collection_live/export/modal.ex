defmodule DataAggregatorWeb.CollectionLive.Export.Modal do
  @moduledoc """
  This module contains the modal to configure an export for collection.
  """

  use DataAggregatorWeb, :live_component

  alias DataAggregator.Records
  alias DataAggregator.Records.Export

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_export() |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="space-y-8">
        <.section_heading
          text={~t"Export records"m}
          description={
            mgettext(
              "You are about to export %{row_count} records. Please choose the column headers for your export file and the data layer to be exported.",
              row_count: @export.rows_count
            )
          }
          class="border-b border-black-white/10 py-4 sm:!items-start"
        />
        <.simple_form
          for={@form}
          as={:story}
          id="export_form"
          class="space-y-8"
          phx-target={@myself}
          phx-submit="export:save"
        >
          <.fieldset>
            <.fieldgroup>
              <section class="border-black-white/25 flex flex-col rounded-lg border border-dashed px-6 py-6">
                <div class="space-y-4">
                  <h4><%= ~t"Select your data headers"m %></h4>
                  <div class="text-sm/6 text-base-content">
                    <.field
                      name="header_source"
                      value="collection_mapping"
                      label="Collection Mapping"
                      description="The column headers will be based on the last file you uploaded"
                      type="radio"
                      required
                      checked={true}
                    />
                    <.field
                      name="header_source"
                      value="dwc_attributes"
                      label="DWC Attributes"
                      description="The Darwin Core attributes will be used as column headers"
                      type="radio"
                      required
                    />
                  </div>
                </div>
              </section>
              <section class="border-black-white/25 flex flex-col rounded-lg border border-dashed px-6 py-6">
                <div class="space-y-4">
                  <h4><%= ~t"Select the data layer to be exported"m %></h4>
                  <div class="text-sm/6 text-base-content">
                    <.field
                      name="data_layer"
                      value="raw"
                      label="Raw"
                      description="The exported data will be the same as the original collection data"
                      type="radio"
                      required
                      checked={true}
                    />
                    <.field
                      name="data_layer"
                      value="encoded"
                      label="Encoded"
                      description="Exported data will consist of enriched data from various thesauri and vocabularies"
                      type="radio"
                      required
                    />
                  </div>
                </div>
              </section>

              <p class="text-base-content/60 mt-1 text-sm">
                * <%= ~t"required to choose an option"m %>
              </p>
            </.fieldgroup>
          </.fieldset>

          <:actions>
            <button type="submit" class="btn btn-primary text-primary-content" disabled={false}>
              <.icon name="hero-arrow-down-tray" />
              <span class="max-sm:hidden"><%= ~t"Export"m %></span>
            </button>
            <button type="button" class="btn btn-ghost" onclick="export_modal.close()">
              <%= ~t"Cancel"m %>
            </button>
          </:actions>
        </.simple_form>
      </div>
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
    %{collection: collection} = socket.assigns
    collection = Records.load!(collection, [:records_to_export_query], lazy?: true)

    export =
      Export.create!(%{
        name: "export-#{collection.name}-#{:os.system_time()}",
        collection: collection,
        mapping: nil,
        records_query: collection.records_to_export_query,
        rows_count: Records.count!(collection.records_to_export_query)
      })

    assign(socket, :export, export)
  end
end
