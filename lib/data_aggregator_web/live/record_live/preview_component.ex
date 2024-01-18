defmodule DataAggregatorWeb.RecordLive.PreviewComponent do
  use DataAggregatorWeb, :html
  use DataAggregatorWeb.CollectionLive.Components
  use Phoenix.Component

  import DataAggregatorWeb.Helpers

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Record

  attr :record, Record, required: true
  attr :current_path_params, :string, required: true
  attr :live_action, :atom, required: true

  def preview(assigns) do
    ~H"""
    <aside class="hidden xl:fixed xl:top-16 xl:right-0 xl:bottom-0 xl:block xl:w-96 xl:overflow-y-auto">
      <.preview_content record={@record} current_path_params={@current_path_params} />
    </aside>

    <.slideover
      id="record-slideover"
      responsive="xl:hidden"
      show={false}
      on_cancel={JS.push("select", value: %{id: @record.id})}
    >
      <div class="flex h-full flex-col">
        <.preview_content
          record={@record}
          current_path_params={@current_path_params}
          slideover_id="record-slideover"
          modal_id="record-modal-edit__button"
        />
      </div>
    </.slideover>
    """
  end

  attr :record, Record, required: true
  attr :record_encoding_results, :any, required: false
  attr :current_path_params, :string, required: true
  attr :slideover_id, :string, default: nil
  attr :modal_id, :string, default: nil

  defp preview_content(assigns) do
    assigns =
      assign(
        assigns,
        record_encoding_results: RecordEncodingResult.filter_by_record!(assigns.record.id),
        attrs_in_categories: attrs_by_category_in_layers(assigns.record)
      )

    ~H"""
    <.sidebar>
      <:header>
        <.sidebar_header sidebar_id={@slideover_id} class="sticky top-0">
          <%= encoded_attribute(@record, :tax_scientific_name) %>
          <:subtitle>
            <div><%= encoded_attribute(@record, :tax_kingdom) %></div>
            <div><%= @record.collection.name %></div>
          </:subtitle>
        </.sidebar_header>
      </:header>
      <div class="divide-base-content/10 w-full divide-y">
        <.heading
          size="lg"
          title={~t"Attributes of the record"m}
          subtitle={~t"Characteristics according to the darwin core standard"m}
        />
        <%= for category <- @attrs_in_categories do %>
          <div class="pt-3">
            <.heading size="sm" title={category.label} subtitle={category.description} />
            <.table id="data_layers-table" rows={category.attributes}>
              <:col :let={attribute} label={~t"Name"}>
                <%= attribute.name %>
              </:col>
              <:col :let={attribute} label={~t"Imported"}>
                <%= attribute.imported %>
              </:col>
              <:col :let={attribute} label={~t"Encoded"}>
                <%= attribute.encoded %>
              </:col>
            </.table>
          </div>
        <% end %>
        <.heading size="lg" title={~t"Record encodings"m} subtitle={~t"Results by catalog"m} />
        <.table id="encoding_result-table" rows={@record_encoding_results}>
          <:col :let={result} label={~t"Catalog"}>
            <%= result.catalog %>
          </:col>
          <:col :let={result} label={~t"State"}>
            <.encoding_state state={result.state} small={true} />
          </:col>
          <:col :let={result} label={~t"Created"}>
            <%= format_datetime(result.inserted_at, format: :short) %>
          </:col>
        </.table>
      </div>
      <:footer>
        <.button
          label={~t"Close"m}
          color="secondary"
          class="inline-flex mr-2"
          phx-click={JS.push("select", value: %{id: @record.id})}
        />
        <.button
          id={@modal_id}
          to={~p"/records/#{@record}/edit?#{@current_path_params}"}
          link_type="live_patch"
          icon="hero-pencil-square-mini"
          label={~t"Edit Record"m}
        />
      </:footer>
    </.sidebar>
    """
  end

  defp attrs_by_category_in_layers(record) do
    for category <- Schema.categories() do
      attributes =
        for attribute <- category.attributes do
          %{
            name: attribute.name,
            imported:
              imported_attribute(
                record,
                String.to_existing_atom("#{category.name}_#{attribute.name}")
              ),
            encoded:
              encoded_attribute(
                record,
                String.to_existing_atom("#{category.name}_#{attribute.name}")
              )
          }
        end

      %{label: category.label, description: category.description, attributes: attributes}
    end
  end

  attr :size, :string, values: ["xs", "sm", "lg", "xl"], default: "lg"
  attr :title, :string, required: true
  attr :subtitle, :string, required: false

  def heading(assigns) do
    ~H"""
    <div class="border-b- p-4">
      <h4 class={"text-#{@size} text-base-content font-bold"}><%= @title %></h4>
      <p :if={@subtitle} class="text-base-content/50 text-sm"><%= @subtitle %></p>
    </div>
    """
  end
end
