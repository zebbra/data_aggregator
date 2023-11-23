defmodule DataAggregatorWeb.ImportLive.Components.MappingForm do
  @moduledoc """
  A form for updating the record column mapping
  """

  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias Phoenix.LiveView.Socket

  alias DataAggregator.DarwinCore
  alias DataAggregator.Records.Import

  @impl true
  def mount(socket) do
    socket = assign_filter(socket)
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()

    {:ok, socket}
  end

  defp column_matches?(column, filter) do
    query = normalize_string(filter[:query].value)

    [column.name, column.mapped_to]
    |> Enum.map(&normalize_string/1)
    |> Enum.any?(&String.contains?(&1, query))
  end

  defp normalize_string(value) do
    value
    |> to_string()
    |> String.downcase()
  end

  defp assign_form(%{assigns: assigns} = socket) do
    form = build_form(assigns)
    assign(socket, :form, form)
  end

  defp build_form(%{import: import}) do
    import
    |> Form.for_update(
      :update_mapping,
      api: DataAggregator.Records,
      as: "import",
      forms: [auto?: true]
    )
    |> to_form()
  end

  defp assign_filter(socket, params \\ %{}) do
    filter = to_form(params, as: :filter)
    assign(socket, :filter, filter)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <.filter_form form={@filter} phx-target={@myself} phx-change="filter" phx-submit="filter" />

      <.mapping_form
        id={@id}
        form={@form}
        filter={@filter}
        phx-target={@myself}
        phx-change="save"
        phx-submit="save"
      />
    </div>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :rest, :global

  defp filter_form(assigns) do
    ~H"""
    <.simple_form for={@form} {@rest}>
      <.input type="search" field={@form[:query]} placeholder={~t"Search mapping"} />
    </.simple_form>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :filter, Phoenix.HTML.Form, required: true
  attr :rest, :global

  defp mapping_form(assigns) do
    assigns = assign(assigns, :options, DarwinCore.Schema.attribute_options())

    ~H"""
    <.simple_form for={@form} {@rest}>
      <div class="grid gap-3 xg:grid-cols-4 md:grid-cols-3">
        <.inputs_for :let={column_form} field={@form[:columns]}>
          <.column_input form={column_form} options={@options} filter={@filter} />
        </.inputs_for>
      </div>
    </.simple_form>
    """
  end

  attr :form, Phoenix.HTML.Form, required: true
  attr :filter, Phoenix.HTML.Form, required: true
  attr :options, :list, required: true

  defp column_input(assigns) do
    %{form: %{data: column}, filter: filter} = assigns
    visible = column_matches?(column, filter)

    assigns = assign(assigns, :visible, visible)

    ~H"""
    <div class={["rounded bg-gray-50 p-3 dark:bg-gray-800", @visible || "hidden"]}>
      <.input
        type="select"
        label={@form.data.name}
        field={@form[:mapped_to]}
        options={@options}
        prompt=""
      />
    </div>
    """
  end

  @impl true
  def handle_event("filter", %{"filter" => params}, socket) do
    socket = assign_filter(socket, params)
    {:noreply, socket}
  end

  def handle_event("validate", %{"import" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    %{"import" => %{"columns" => columns}} = params
    mappings = for {_, col} <- columns, do: Map.take(col, ["name", "mapped_to"])

    %Socket{assigns: %{import: import}} = socket
    Import.update_mapping(import, mappings)
    {:noreply, socket}
  end
end
