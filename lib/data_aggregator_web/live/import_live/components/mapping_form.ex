defmodule DataAggregatorWeb.ImportLive.Components.MappingForm do
  @moduledoc """
  A form for updating the record column mapping
  """

  use DataAggregatorWeb, :live_component
  use DataAggregatorWeb.ImportLive.Components

  alias AshPhoenix.Form

  alias DataAggregator.DarwinCore
  alias DataAggregator.Records
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
    import_with_mappings = Records.load!(import, [:mappings], lazy?: true)

    import
    |> Form.for_update(
      :update_mapping,
      api: DataAggregator.Records,
      as: "import",
      forms: [
        columns: [
          data: import_with_mappings.mappings,
          type: :list,
          resource: Import.Column,
          create_action: :create_mapping,
          update_action: :update_mapping
        ]
      ]
    )
    |> add_missing_mappings()
    |> to_form()
  end

  defp add_missing_mappings(%Form{data: import} = form) do
    import_with_missing_mappings = Records.load!(import, [:missing_mappings], lazy?: true)
    add_missing_mapping = &Form.add_form(&2, [:columns], params: %{"mapped_to" => &1.name})

    import_with_missing_mappings.missing_mappings
    |> Enum.flat_map(&DarwinCore.Schema.Category.prefixed_attributes/1)
    |> Enum.reduce(form, add_missing_mapping)
  end

  defp assign_filter(socket, params \\ %{}) do
    filter = to_form(params, as: :filter)
    assign(socket, :filter, filter)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4 lg:min-w-[50rem]">
      <.header>
        Mappings
        <:subtitle>Map columns to record attributes</:subtitle>

        <:actions>
          <.filter_form form={@filter} phx-target={@myself} phx-change="filter" phx-submit="filter" />
        </:actions>
      </.header>

      <.import_mapping_validation import={@import} />

      <.mapping_form
        id={@id}
        form={@form}
        filter={@filter}
        target={@myself}
        phx-change="validate"
        phx-submit="save"
      />
    </div>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:rest, :global)

  defp filter_form(assigns) do
    ~H"""
    <.simple_form for={@form} {@rest}>
      <.input type="search" field={@form[:query]} placeholder={~t"Search mapping"} class="input-sm" />
    </.simple_form>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:filter, Phoenix.HTML.Form, required: true)
  attr(:target, :string, required: true)
  attr(:rest, :global)

  defp mapping_form(assigns) do
    # |> Enum.reject(& &1.mapped?)
    name_opts =
      Enum.map(assigns.form.data.columns, & &1.name)

    assigns = assign(assigns, :name_opts, name_opts)
    assigns = assign(assigns, :mapped_to_opts, DarwinCore.Schema.attribute_options())

    ~H"""
    <.simple_form for={@form} phx-target={@target} {@rest}>
      <table class="table">
        <thead>
          <tr>
            <th />
            <th>Column</th>
            <th />
            <th>Mapped to</th>
          </tr>
        </thead>

        <tbody>
          <.inputs_for :let={column_form} field={@form[:columns]}>
            <.column_input
              form={column_form}
              target={@target}
              mapped_to_opts={@mapped_to_opts}
              name_opts={@name_opts}
              filter={@filter}
            />
          </.inputs_for>

          <tr>
            <td class="pr-0">
              <button
                class="btn btn-sm btn-circle"
                type="button"
                phx-click="mapping:add"
                phx-value-path={@form[:columns].name}
                phx-target={@target}
              >
                <.icon name="hero-plus" />
              </button>
            </td>
            <td class="text-base-content/75">Add mapping</td>
          </tr>
        </tbody>
      </table>

      <:actions>
        <.button type="submit">
          Save
        </.button>
        <.link class="btn btn-simple rounded-full" patch={~p"/imports/#{@form.data}"}>
          Cancel
        </.link>
      </:actions>
    </.simple_form>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:filter, Phoenix.HTML.Form, required: true)
  attr(:target, :string, required: true)
  attr(:mapped_to_opts, :list, required: true)
  attr(:name_opts, :list, required: true)

  defp column_input(assigns) do
    %{form: form, filter: filter} = assigns

    visible = mapping_form_visible?(form, filter)
    assigns = assign(assigns, :visible, visible)

    mapped_to_opts =
      case form[:name].value do
        nil -> assigns.mapped_to_opts
        name -> [{"Extra Attribute", name} | assigns.mapped_to_opts]
      end

    assigns = assign(assigns, :mapped_to_opts, mapped_to_opts)

    ~H"""
    <tr class={[
      !@visible && "hidden",
      @form.source.changed? && "bg-info/10",
      @form.source.added? && "bg-success/10"
    ]}>
      <td class="w-8 pr-0 align-top">
        <button
          type="button"
          phx-click="mapping:remove"
          phx-value-path={@form.name}
          phx-target={@target}
          class="btn btn-ghost btn-circle btn-sm text-error mt-2 grow-0 hover:bg-error hover:text-error-content"
        >
          <.icon name="hero-trash" />
        </button>
      </td>
      <td class="align-top">
        <.input type="select" field={@form[:name]} options={@name_opts} prompt="Select column" />
      </td>
      <td class="w-8 px-0 text-center align-top">
        <.icon name="hero-chevron-right" class="mt-3" />
      </td>
      <td class="align-top">
        <.input
          type="select"
          field={@form[:mapped_to]}
          options={@mapped_to_opts}
          prompt="Select attribute"
          disabled={@form[:name].value == nil}
        />
      </td>
    </tr>
    """
  end

  defp mapping_form_visible?(form, filter) do
    query = normalize_string(filter[:query].value)

    [:name, :mapped_to]
    |> Enum.map(&form[&1].value)
    |> Enum.map(&normalize_string/1)
    |> Enum.any?(&String.contains?(&1, query))
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

  def handle_event("mapping:add", %{"path" => path}, socket) do
    form = Form.add_form(socket.assigns.form, path)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("mapping:remove", %{"path" => path}, socket) do
    form = Form.remove_form(socket.assigns.form, path)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"import" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, import} ->
          notify_parent({:saved, import})

          socket
          |> put_flash(:info, ~t"Mapping updated"m)
          |> push_patch(to: socket.assigns.patch)

        {:error, form} ->
          socket
          |> put_flash(:error, ~t"Unable to update mapping"m)
          |> assign(:form, form)
      end

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
