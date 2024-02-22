defmodule DataAggregatorWeb.CollectionLive.Import.Components.Mapping do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Import.Components, only: [import_mapping_validation: 1]
  import DataAggregatorWeb.CollectionLive.Import.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

  alias AshPhoenix.Form
  alias DataAggregator.DarwinCore
  alias DataAggregator.Records
  alias DataAggregator.Records.Import

  require Logger

  @mandatory_attributes DarwinCore.Schema.mandatory_prefixed_attribute_names()

  @impl true
  def mount(socket) do
    socket = assign_filter(socket)

    {:ok, socket}
  end

  @impl true
  def update(%{import: import} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:name_opts, available_column_names(import))
      |> assign(:mapped_to_opts, available_attribute_options(import))
      |> assign(:disabled, Enum.any?(import.missing_mappings))
      |> assign(
        :reuse_mapping,
        Enum.any?(import.missing_mappings) && is_nil(import.collection.import_mapping) == false
      )
      |> assign_form()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.stepper current={current_step(@action)} links={valid_links(@collection, @import)} class="" />
      <div class="space-y-8">
        <.heading
          title={~t"Mappings"m}
          subtitle={~t"Map columns to record attributes"m}
          class="border-b border-black-white/10 py-4"
        >
          <:actions>
            <.filter_form
              form={@filter}
              phx-target={@myself}
              phx-change="mapping:filter"
              phx-submit="filter"
              phx-window-keydown={JS.focus(to: "#filter_query")}
              phx-key="/"
            />
          </:actions>
        </.heading>
        <.import_mapping_validation
          :if={@show_validation && @import}
          import={@import}
          on_hide={JS.push("validation:hide", target: @myself)}
        />
        <.simple_form
          id="import_mapping_form"
          for={@form}
          class="space-y-8"
          novalidate
          phx-target={@myself}
          phx-change="mapping:validate"
          phx-submit="mapping:save"
        >
          <div :if={@reuse_mapping} class="alert alert-info bg-info/10 text-info text-sm">
            <.icon name="hero-information-circle-solid" />
            <span><%= ~t"Reuse mapping from previous import"m %></span>
            <.link
              type="button"
              class="link link-hover link-info font-semibold flex items-center gap-x-1 hover:no-underline rounded-md"
              phx-click="mapping:apply"
              phx-target={@myself}
            >
              <%= ~t"Load"m %> <.icon name="hero-arrow-right-micro" />
            </.link>
          </div>
          <.fieldset
            legend={~t"Required attributes"m}
            text={~t"Please map all required attributes to one of your columns before continueing."m}
          >
            <.fieldgroup class="grid grid-cols-1 items-center gap-x-4 sm:grid-cols-3 gap-y-8">
              <.inputs_for :let={column_form} field={@form[:columns]}>
                <.column_input
                  form={column_form}
                  filter={@filter}
                  name_opts={@name_opts}
                  mapped_to_opts={@mapped_to_opts}
                  mandatory={mandatory?(column_form)}
                  target={@myself}
                  path={@form[:columns].name}
                  disabled={@disabled}
                />
              </.inputs_for>
            </.fieldgroup>
          </.fieldset>

          <:actions>
            <button type="submit" class="btn btn-neutral"><%= ~t"Save"m %></button>
            <button type="reset" class="btn btn-ghost"><%= ~t"Reset"m %></button>
            <button type="button" class="btn btn-ghost" onclick="import_modal.close()">
              <%= ~t"Cancel"m %>
            </button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:rest, :global)

  defp filter_form(assigns) do
    ~H"""
    <.simple_form for={@form} {@rest} class="w-full">
      <.custom_field
        type="search"
        field={@form[:query]}
        placeholder={~t"Search mapping"}
        class="input input-bordered input-sm max-sm:text-baseflex items-center rounded-full flex-row gap-2"
      >
        <:content :let={field}>
          <.icon name="hero-magnifying-glass" class="size-5 text-base-content/50" />
          <.input {field} icon_start="hero-magnifying-glass" class="" inside />
          <kbd class="kbd kbd-sm max-sm:hidden">/</kbd>
        </:content>
      </.custom_field>
    </.simple_form>
    """
  end

  attr(:form, Phoenix.HTML.Form, required: true)
  attr(:filter, Phoenix.HTML.Form, required: true)
  attr(:mandatory, :boolean, default: false)
  attr(:name_opts, :list, required: true)
  attr(:mapped_to_opts, :list, required: true)
  attr(:target, :string, required: true)
  attr(:path, :string, required: true)
  attr(:disabled, :boolean, default: false)

  defp column_input(%{mandatory: true} = assigns) do
    %{form: form, filter: filter, name_opts: name_opts} = assigns

    name = coalesce_name(form)
    options = add_selected_column(name, name_opts)
    visible = mapping_form_visible?(form, filter)

    assigns =
      assigns
      |> assign(:column_name, name)
      |> assign(:options, options)
      |> assign(:last_mandatory, form.index == length(@mandatory_attributes) - 1)
      |> assign(:visible, visible)

    ~H"""
    <.input type="hidden" field={@form[:mapped_to]} />
    <.field
      type="select"
      field={@form[:name]}
      options={@options}
      prompt={~t"Select column"m}
      hidden={@visible == false}
      inline
      required
    >
      <:custom_label>
        <.label
          for={@form[:name].id}
          class="label px-0 pt-0 sm:pb-0 sm:block overflow-x-scroll no-scrollbar"
        >
          <.attribute_badge name={coalesce_mapped_to(@form)} mapped={@column_name not in ["", nil]} />
        </.label>
      </:custom_label>
    </.field>

    <%!-- This is a bit hackisch, but we need to inline the column badge
    selection section in between the last mandatory input and the first
    optional column mapping --%>
    <.fieldset
      :if={@last_mandatory}
      class="sm:col-span-3"
      legend={~t"Additional columns"m}
      text={~t"Click on columns to add additional column to attribute mappings."m}
    >
      <.fieldgroup class="space-y-0">
        <button
          :for={col <- @name_opts}
          :if={column_name_visible?(col, @filter)}
          type="button"
          phx-click="mapping:add"
          phx-value-path={@path}
          phx-value-name={col}
          phx-target={@target}
          disabled={@disabled}
          class="bg-base-200 mr-1 mb-1 inline-flex cursor-pointer rounded px-2 py-1 text-xs enabled:hover:bg-base-300 disabled:text-base-content/50"
        >
          <%= col %>
        </button>
      </.fieldgroup>
    </.fieldset>
    """
  end

  defp column_input(assigns) do
    %{form: form, filter: filter, mapped_to_opts: mapped_to_opts} = assigns

    mapped_to_opts =
      case form[:name].value do
        nil -> mapped_to_opts
        name -> [{"Extra Attribute", name} | mapped_to_opts]
      end

    mapped_to_opts =
      form
      |> coalesce_mapped_to()
      |> add_selected_attribute(mapped_to_opts)
      |> remove_empty_categories()

    visible = mapping_form_visible?(form, filter)

    assigns =
      assigns
      |> assign(:mapped_to_opts, mapped_to_opts)
      |> assign(:visible, visible)
      |> assign(:column_name, coalesce_name(form))

    ~H"""
    <.input type="hidden" field={@form[:name]} />
    <.custom_field
      field={@form[:mapped_to]}
      type="select"
      class="grid-cols-[subgrid] grid sm:col-span-3"
      options={@mapped_to_opts}
      prompt={~t"Select attribute"m}
      hidden={@visible == false}
    >
      <:content :let={field}>
        <.label for={@form[:mapped_to].id} class="sm:pb-0 sm:block max-sm:truncate max-sm:mr-11">
          <span class="line-clamp-2">
            <%= @column_name %>
          </span>
        </.label>

        <div class="inline-flex gap-x-3 sm:col-span-2">
          <.input {field} class="w-full" />
          <button
            type="button"
            phx-click="mapping:remove"
            phx-value-path={@form.name}
            phx-value-name={@column_name}
            phx-target={@target}
            class="btn btn-ghost btn-circle btn-sm text-error mt-2 grow-0 hover:bg-error hover:text-error-content sm:tooltip-error sm:tooltip-left sm:tooltip"
            data-tip={~t"Remove mapping"m}
          >
            <.icon name="hero-trash" />
          </button>
        </div>
        <.errors
          errors={field.errors}
          id={field.id}
          class="sm:col-span-3 sm:justify-self-end mt-2 mr-11"
        />
      </:content>
    </.custom_field>
    """
  end

  attr(:name, :string,
    required: true,
    doc: "The name of the attribute prefixed with the category"
  )

  attr(:mapped, :boolean, default: false, doc: "Whether the attribute is mapped to a column")

  defp attribute_badge(assigns) do
    parts = String.split(assigns.name, "_")
    category = List.first(parts)

    name =
      parts
      |> List.delete_at(0)
      |> Enum.join("_")

    assigns = assign(assigns, category: category, name: name)

    ~H"""
    <div class="inline-flex text-xs">
      <div class={[
        "rounded-l px-2 py-1 uppercase",
        if(@mapped == true, do: "bg-info text-info-content", else: "bg-error text-white")
      ]}>
        <%= @category %>
      </div>
      <div class={[
        "rounded-r px-2 py-1",
        if(@mapped == true, do: "bg-info/10 text-base-content", else: "bg-error/10 text-error")
      ]}>
        <%= @name %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("validation:hide", _, socket) do
    {:noreply, assign(socket, :show_validation, false)}
  end

  @impl true
  def handle_event("mapping:filter", %{"filter" => params}, socket) do
    socket = assign_filter(socket, params)
    {:noreply, socket}
  end

  def handle_event("mapping:add", %{"path" => path, "name" => name}, socket) do
    %{form: form, name_opts: name_opts} = socket.assigns

    socket =
      socket
      |> assign(:name_opts, name_opts -- [name])
      |> assign(:form, Form.add_form(form, path, params: %{"name" => name}))
      |> assign_filter()

    {:noreply, socket}
  end

  @impl true
  def handle_event("mapping:remove", %{"path" => path, "name" => name}, socket) do
    %{form: form, name_opts: name_opts} = socket.assigns

    socket =
      socket
      |> assign(:name_opts, name_opts ++ [name])
      |> assign(:form, Form.remove_form(form, path))
      |> assign_filter()

    {:noreply, socket}
  end

  @impl true
  def handle_event("mapping:validate", %{"import" => params}, socket) do
    disabled = Enum.any?(@mandatory_attributes -- extract_mapped_to_with_name(params))

    socket =
      socket
      |> assign(:name_opts, available_column_names(socket.assigns.import, params))
      |> assign(:mapped_to_opts, available_attribute_options(params))
      |> assign(:form, Form.validate(socket.assigns.form, params))
      |> assign(:disabled, disabled)

    {:noreply, socket}
  end

  @impl true
  def handle_event("mapping:save", %{"import" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, import} ->
          socket
          |> put_flash(:info, ~t"Mapping updated"m)
          |> push_patch(to: ~p"/collections/#{socket.assigns.collection}/imports/#{import}/summary")

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("mapping:apply", _params, socket) do
    %{assigns: %{import: import}} = socket

    socket =
      case Import.update_mapping(import, import.collection.import_mapping) do
        {:ok, import} ->
          socket
          |> assign(:import, import)
          |> push_patch(to: ~p"/collections/#{import.collection}/imports/#{import}/edit")

        {:error, error} ->
          Logger.error(error)
          put_flash(socket, :error, ~t"Mapping from collection could not be used"m)
      end

    {:noreply, socket}
  end

  defp assign_filter(socket, params \\ %{}) do
    filter = to_form(params, as: :filter)
    assign(socket, :filter, filter)
  end

  defp mapping_form_visible?(form, filter) do
    query = normalize_string(filter[:query].value)

    [:name, :mapped_to]
    |> Enum.map(&form[&1].value)
    |> Enum.map(&normalize_string/1)
    |> Enum.any?(&String.contains?(&1, query))
  end

  defp column_name_visible?(name, filter) do
    query = normalize_string(filter[:query].value)
    name |> normalize_string() |> String.contains?(query)
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
    import_with_mappings = Records.load!(import, [:mappings, :missing_mappings], lazy?: true)
    mappings = Enum.sort_by(import_with_mappings.mappings, &{mandatory?(&1.mapped_to)}, :desc)

    import
    |> Form.for_update(
      :update_mapping,
      api: DataAggregator.Records,
      as: "import",
      forms: [
        columns: [
          data: mappings,
          type: :list,
          resource: Import.Column,
          create_action: :create_mapping,
          update_action: :update_mapping
        ]
      ]
    )
    |> to_form()
  end

  defp mandatory?(%Phoenix.HTML.Form{} = form), do: mandatory?(coalesce_mapped_to(form))
  defp mandatory?(mapped_to) when is_binary(mapped_to), do: mandatory?(String.to_atom(mapped_to))
  defp mandatory?(mapped_to) when is_atom(mapped_to), do: mapped_to in @mandatory_attributes
  defp mandatory?(_), do: false

  defp coalesce_name(%Phoenix.HTML.Form{} = form) do
    form.params["name"] || (form.data && form.data.name)
  end

  defp coalesce_mapped_to(%Phoenix.HTML.Form{} = form) do
    form.params["mapped_to"] || (form.data && form.data.mapped_to)
  end

  defp add_selected_column(nil, options) do
    options
  end

  defp add_selected_column("", options) do
    options
  end

  defp add_selected_column(name, options) do
    [name | options]
  end

  defp add_selected_attribute(nil, options) do
    options
  end

  defp add_selected_attribute("", options) do
    options
  end

  defp add_selected_attribute(prefixed_attribute, options) do
    category = DarwinCore.Schema.category_from_prefixed_attribute_name(prefixed_attribute)

    if is_nil(category) do
      options
    else
      description = Map.fetch!(category, :description)
      attribute = DarwinCore.Schema.attribute_name_without_prefix(prefixed_attribute)
      insert_attribute(description, attribute, prefixed_attribute, options)
    end
  end

  defp insert_attribute(category, attribute, prefixed_attribute, options) do
    Enum.map(options, fn {desc, attrs} ->
      if desc == category do
        {desc, [{attribute, String.to_atom(prefixed_attribute)} | attrs]}
      else
        {desc, attrs}
      end
    end)
  end

  defp available_column_names(%Import{} = import) do
    import.columns
    |> Enum.filter(&(&1.mapped? == false))
    |> Enum.map(& &1.name)
  end

  defp available_column_names(%Import{} = import, params) do
    columns_in_use = extract_column_names(params)
    Enum.map(import.columns, & &1.name) -- columns_in_use
  end

  defp extract_column_names(%{"columns" => columns} = _params) do
    columns
    |> Enum.map(fn {_index, column} -> column["name"] end)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_column_names(_params), do: []

  defp extract_mapped_to_with_name(%{"columns" => columns} = _params) do
    columns
    |> Enum.filter(fn {_index, column} ->
      column["mapped_to"] not in ["", nil] && column["name"] not in ["", nil]
    end)
    |> Enum.map(fn {_idnex, column} -> String.to_atom(column["mapped_to"]) end)
  end

  defp extract_mapped_to_with_name(_params), do: []

  defp available_attribute_options(%Import{} = import) do
    import |> attributes_in_use() |> filter_attribute_options()
  end

  defp available_attribute_options(params) do
    params |> extract_column_mapped_to() |> filter_attribute_options()
  end

  defp attributes_in_use(%Import{} = import) do
    import.columns
    |> Enum.filter(&(&1.mapped? == true))
    |> Enum.map(&String.to_atom(&1.mapped_to))
  end

  defp extract_column_mapped_to(%{"columns" => columns} = _params) do
    columns
    |> Enum.map(fn {_index, column} -> column["mapped_to"] end)
    |> Enum.reject(&(&1 in ["", nil]))
    |> Enum.map(&String.to_atom/1)
  end

  defp extract_column_mapped_to(_params), do: []

  defp remove_empty_categories(options) do
    Enum.reject(options, fn {_, attrs} -> is_list(attrs) && Enum.empty?(attrs) end)
  end

  defp filter_attribute_options(filter_list) do
    Enum.map(DarwinCore.Schema.attribute_options(), fn {category, attribute_tuple} ->
      filtered_map =
        Enum.reject(attribute_tuple, fn {_, prefixed_attribute} ->
          Enum.member?(filter_list, prefixed_attribute)
        end)

      {category, filtered_map}
    end)
  end

  defp valid_links(collection, import) do
    summary =
      if Enum.empty?(import.missing_mappings),
        do: ~p"/collections/#{collection}/imports/#{import}/summary"

    [nil, nil, summary]
  end
end
