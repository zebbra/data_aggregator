defmodule DataAggregatorWeb.CollectionLive.Import.Components.Mapping do
  @moduledoc """
  DWC attribute <-> Import column mapping module for the collection import live view.

  ## Assigns

  `@import.mappings:` This is an `Ash.Resource.Calculation`. Initially this field
  is set to the missing column mappings based on the required attributes using the
  attribute definitions from `DataAggregator.DarwinCore.Schema`.
  (See `DataAggregator.Records.Import.Calculations.MissingMappings`)
  """
  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Components, only: [import_mapping_validation: 1]

  import DataAggregatorWeb.CollectionLive.Import.Helpers,
    only: [current_step: 1, not_mappable_fields: 0, attribute_options: 0]

  alias DataAggregator.DarwinCore
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Import
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.Socket

  @mandatory_attributes Enum.map(
                          DarwinCore.Schema.mandatory_prefixed_attribute_names(),
                          &Atom.to_string/1
                        )

  @impl true
  def update(%{import: import} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> init(import)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title_class="!-mr-5 -m-1 p-1 w-full">
        <.stepper current={current_step(@action)} links={valid_links(@collection, @import, @meta)} />
        <.section_heading
          text={~t"Mappings"m}
          description={~t"Map columns to record attributes"m}
          class="mt-4 sm:!items-start"
          break_at="sm"
        >
          <:actions>
            <.simple_form
              for={@filter}
              phx-target={@myself}
              phx-change="mapping:filter"
              phx-submit="filter"
              phx-window-keydown={JS.focus(to: "#filter_query")}
              phx-key="/"
              onkeydown="return event.key != 'Enter';"
              class="w-full"
            >
              <.custom_field
                type="search"
                field={@filter[:query]}
                placeholder={~t"Search mapping"}
                class="input input-bordered flex-row items-center gap-2 rounded-full max-sm:text-base sm:inline-flex"
              >
                <:content :let={field}>
                  <.icon name="hero-magnifying-glass" class="size-5 text-base-content/50" />
                  <.input {field} class="" inside />
                  <kbd class="kbd kbd-sm max-sm:hidden">/</kbd>
                </:content>
              </.custom_field>
            </.simple_form>
          </:actions>
        </.section_heading>
      </.modal_header>

      <.simple_form
        id="import_mapping_form"
        for={@form}
        novalidate
        phx-target={@myself}
        phx-change="mapping:validate"
        phx-submit="mapping:save"
        class="contents"
      >
        <div class="no-scrollbar h-full space-y-12 overflow-y-auto px-6 py-8">
          <.import_mapping_validation
            :if={@show_validation && @import}
            import={@import}
            on_hide={JS.push("validation:hide", target: @myself)}
          />
          <section id="quick_start" class="space-y-6">
            <.section_heading
              text={~t"Quick Start"m}
              description="Use one of the following actions to quickly map your columns to the Darwin Core format."
              size="md"
            />
            <div class="grid gap-4 sm:grid-cols-2">
              <button
                type="button"
                phx-click="mapping:auto_match"
                phx-target={@myself}
                class="btn btn-outline border-base-content/20"
              >
                <.icon name="hero-sparkles-mini" /> {~t"Try auto-mapping"m}
              </button>
              <button
                type="button"
                phx-click="mapping:load"
                phx-target={@myself}
                class="btn btn-outline border-base-content/20"
              >
                <.icon name="hero-arrow-path-solid" /> {~t"Load existing mapping"m}
              </button>
              <p :if={@quick_start_error} class="text-error -mb-6 text-sm italic sm:col-span-2">
                {@quick_start_error}
              </p>
            </div>
          </section>

          <section id="mandatory_attributes">
            <.fieldset
              legend={~t"Required attributes"m}
              text={
                ~t"Please map all required attributes to one of your columns before continueing."m
              }
            >
              <.fieldgroup class="grid grid-cols-1 items-center gap-x-4 gap-y-8 sm:grid-cols-3">
                <.inputs_for :let={column_form} field={@form[:columns]} skip_hidden={true}>
                  <%= if mandatory?(column_form) do %>
                    <section id={Form.input_value(column_form, :mapped_to)} class="contents">
                      <%= for {name, value_or_values} <- column_form.hidden, name = name_for_value_or_values(column_form, name, value_or_values), value <- List.wrap(value_or_values) do %>
                        <input type="hidden" name={name} value={value} />
                      <% end %>
                      <input
                        type="hidden"
                        name={Form.input_name(column_form, :mapped_to)}
                        value={Form.input_value(column_form, :mapped_to)}
                      />

                      <.field
                        type="combobox"
                        label={
                          Form.input_value(column_form, :mapped_to)
                          |> DarwinCore.Schema.dwc_field_from_prefixed_attribute_name()
                        }
                        field={column_form[:name]}
                        options={maybe_add_selected_column_name(column_form, @available_columns)}
                        prompt={~t"Select a column"m}
                        hidden={column_form_visible?(column_form, @filter) == false}
                        inline
                        required
                        data-portal="import_modal"
                      />
                    </section>
                  <% end %>
                </.inputs_for>
              </.fieldgroup>
            </.fieldset>
          </section>

          <section id="additional_columns">
            <.fieldset
              class="sm:col-span-3"
              legend={~t"Additional columns"m}
              text={~t"Click on columns to add additional column to attribute mappings."m}
            >
              <:legend_actions :if={length(@available_columns) > 0}>
                <button
                  type="button"
                  phx-click="mapping:add_all"
                  phx-target={@myself}
                  phx-value-path={@form[:columns].name}
                  disabled={@invalid?}
                  class="btn btn-outline border-base-content/20"
                >
                  <.icon name="hero-plus-circle-mini" class="size-6" /> {~t"Add all"m}
                </button>
              </:legend_actions>

              <button
                :for={col <- @available_columns}
                :if={column_name_visible?(col, @filter)}
                type="button"
                phx-click="mapping:add"
                phx-value-path={@form[:columns].name}
                phx-value-name={col}
                phx-target={@myself}
                disabled={@invalid?}
                class="bg-base-200 mr-2.5 mb-2 inline-flex cursor-pointer rounded px-2 py-1 text-sm first-of-type:mt-6 enabled:hover:bg-base-300 disabled:text-base-content/50"
              >
                {col}
              </button>

              <.fieldgroup class="grid grid-cols-1 items-center gap-x-4 gap-y-8 sm:grid-cols-3">
                <.inputs_for :let={column_form} field={@form[:columns]} skip_hidden={true}>
                  <%= if optional?(column_form) do %>
                    <section id={Form.input_value(column_form, :name)} class="contents">
                      <%= for {name, value_or_values} <- column_form.hidden, name = name_for_value_or_values(column_form, name, value_or_values), value <- List.wrap(value_or_values) do %>
                        <input type="hidden" name={name} value={value} />
                      <% end %>
                      <input
                        type="hidden"
                        name={Form.input_name(column_form, :name)}
                        value={Form.input_value(column_form, :name)}
                      />

                      <.custom_field
                        type="combobox"
                        max_options={1000}
                        dropup
                        label={Form.input_value(column_form, :name)}
                        field={column_form[:mapped_to]}
                        options={maybe_add_selected_attribute(column_form, @available_attributes)}
                        prompt={~t"Select an attribute"m}
                        class="grid-cols-[subgrid] grid sm:col-span-3"
                        hidden={column_form_visible?(column_form, @filter) == false}
                        required
                      >
                        <:content :let={field}>
                          <.label
                            for={Form.input_id(column_form, :mapped_to)}
                            label={field.label}
                            class="label self-center px-0 pt-0 sm:block sm:pb-0"
                          />

                          <div class="inline-flex gap-x-3 sm:col-span-2">
                            <.input {field} class="w-full" />
                            <button
                              type="button"
                              phx-click="mapping:remove"
                              phx-value-path={column_form.name}
                              phx-value-name={Form.input_value(column_form, :name)}
                              phx-target={@myself}
                              class="btn btn-ghost btn-circle btn-sm text-error mt-2 grow-0 hover:bg-error hover:text-error-content sm:tooltip-error sm:tooltip-left sm:tooltip"
                              data-tip={~t"Remove mapping"m}
                            >
                              <.icon name="hero-trash" />
                            </button>
                          </div>

                          <.errors
                            errors={field.errors}
                            id={field.id}
                            class="mt-2 mr-11 sm:col-span-3 sm:justify-self-end"
                          />
                        </:content>
                      </.custom_field>
                    </section>
                  <% end %>
                </.inputs_for>
              </.fieldgroup>
            </.fieldset>
          </section>
        </div>

        <:actions modal>
          <button type="submit" class="btn btn-primary">
            {~t"Update mapping"m}
          </button>
          <button type="button" class="btn btn-ghost" onclick="import_modal.close()">
            {~t"Cancel"m}
          </button>
          <div class="grow">
            <button
              type="button"
              phx-click="mapping:reset"
              phx-target={@myself}
              class="btn btn-ghost !-mx-4"
            >
              {~t"Reset mapping"m}
            </button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validation:hide", _, socket) do
    socket
    |> assign(:show_validation, false)
    |> noreply()
  end

  @impl true
  def handle_event("mapping:filter", %{"filter" => params}, socket) do
    socket
    |> assign_filter(params)
    |> noreply()
  end

  @impl true
  def handle_event("mapping:add", %{"path" => path, "name" => name}, socket) do
    %{form: form, available_columns: available_columns} = socket.assigns

    form =
      AshPhoenix.Form.add_form(form, path,
        params: %{"name" => name, "mapped_to" => name},
        prepend: true
      )

    socket
    |> assign(:form, form)
    |> assign(:available_columns, available_columns -- [name])
    |> assign_filter()
    |> noreply()
  end

  @impl true
  def handle_event("mapping:add_all", %{"path" => path}, socket) do
    %{form: form, available_columns: available_columns} = socket.assigns

    form =
      Enum.reduce(available_columns, form, fn name, form ->
        AshPhoenix.Form.add_form(form, path,
          params: %{"name" => name, "mapped_to" => name},
          validate?: false
        )
      end)

    socket
    |> assign(:form, form)
    |> assign(:available_columns, [])
    |> assign_filter()
    |> noreply()
  end

  @impl true
  def handle_event("mapping:remove", %{"path" => path, "name" => name}, socket) do
    %{form: form, available_columns: available_columns} = socket.assigns

    form = AshPhoenix.Form.remove_form(form, path)

    socket
    |> assign(:form, form)
    |> assign(:available_columns, available_columns ++ [name])
    |> assign_filter()
    |> noreply()
  end

  @impl true
  def handle_event("mapping:reset", _, socket) do
    %{import: import} = socket.assigns

    socket
    |> init(import)
    |> noreply()
  end

  @impl true
  def handle_event("mapping:validate", %{"import" => params}, socket) do
    %{form: form} = socket.assigns

    form = AshPhoenix.Form.validate(form, params)

    socket
    |> assign(:form, form)
    |> update_available_columns(params)
    |> update_available_attributes(params)
    |> assign(:invalid?, form.source.valid? == false)
    |> assign(:quick_start_error, nil)
    |> noreply()
  end

  @impl true
  def handle_event("mapping:save", %{"import" => params}, socket) do
    %{form: form, collection: collection, meta: meta} = socket.assigns

    socket =
      case AshPhoenix.Form.submit(form, params: params) do
        {:ok, import} ->
          push_patch(socket,
            to: build_path(~p"/datasets/#{collection}/imports/#{import}/summary", meta)
          )

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("mapping:load", _, socket) do
    %{import: import, current_user: actor} = socket.assigns

    with {:ok, collection_mapping} <- collection_mapping_from_import(import),
         {:ok, mapped_collection_mapping} <- collection_mapping_mapped(collection_mapping),
         {:ok, matched_columns} <-
           collection_mapping_matched(mapped_collection_mapping, import.columns) do
      data =
        matched_columns
        |> ensure_required_attributes()
        |> Enum.reject(fn column ->
          not_mappable_data = not_mappable_fields() |> Map.keys() |> Enum.map(&Atom.to_string/1)

          column.mapped_to in not_mappable_data
        end)

      import = %{import | mappings: data}

      socket
      |> assign(:form, build_form(import, actor))
      |> assign_available_columns(import)
      |> assign_available_attributes(import)
      |> assign(:invalid?, mapping_valid?(import) == false)
      |> assign(:quick_start_error, nil)
      |> assign_filter()
      |> noreply()
    else
      {:error, reason} ->
        socket
        |> assign(:quick_start_error, reason)
        |> noreply()
    end
  end

  @impl true
  def handle_event("mapping:auto_match", _, socket) do
    %{import: import, current_user: actor} = socket.assigns

    case auto_mapping_matched(import) do
      {:ok, matched_columns} ->
        data = ensure_required_attributes(matched_columns)

        import = %{import | mappings: data}

        socket
        |> assign(:form, build_form(import, actor))
        |> assign_available_columns(import)
        |> assign_available_attributes(import)
        |> assign(:invalid?, mapping_valid?(import) == false)
        |> assign(:quick_start_error, nil)
        |> assign_filter()
        |> noreply()

      {:error, reason} ->
        socket
        |> assign(:quick_start_error, reason)
        |> noreply()
    end
  end

  defp collection_mapping_from_import(import) do
    case import.collection.import_mapping do
      nil -> {:error, ~t"Dataset mapping not found"m}
      import_mapping -> {:ok, import_mapping}
    end
  end

  defp collection_mapping_mapped(collection_mapping) do
    mapped =
      Enum.filter(collection_mapping, fn %{"mapped_to" => mapped_to} ->
        not is_nil(mapped_to)
      end)

    case length(mapped) do
      0 -> {:error, ~t"Dataset mapping is empty"m}
      _ -> {:ok, mapped}
    end
  end

  defp collection_mapping_matched(mapped_collection_mapping, columns) do
    mapped_collection_mapping_names = Enum.map(mapped_collection_mapping, & &1["name"])

    matched_columns =
      columns
      |> Enum.filter(&(&1.name in mapped_collection_mapping_names))
      |> Enum.map(&apply_mapping(&1, mapped_collection_mapping))

    case length(matched_columns) do
      0 -> {:error, ~t"The selected mapping isn't valid for the current import file"m}
      _ -> {:ok, matched_columns}
    end
  end

  defp apply_mapping(column, mapped_collection_mapping) do
    mapping =
      Enum.find(mapped_collection_mapping, fn %{"name" => name} -> name == column.name end)

    %{column | mapped_to: mapping["mapped_to"], mapped?: true}
  end

  defp auto_mapping_matched(import) do
    prefixed_attribute_to_dwc_field_mapping =
      Enum.reject(Schema.prefixed_attribute_names_and_dwc_fields(), fn {key, _} ->
        key in Map.keys(not_mappable_fields())
      end)

    dwc_field_names =
      Enum.map(prefixed_attribute_to_dwc_field_mapping, fn {_, dwc_field} -> dwc_field end)

    matched_columns =
      import.columns
      |> Enum.filter(fn column -> column.name in dwc_field_names end)
      |> Enum.map(&apply_auto_mapping(&1, prefixed_attribute_to_dwc_field_mapping))

    case length(matched_columns) do
      0 -> {:error, ~t"Auto-mapping could not detect any matching columns"m}
      _ -> {:ok, matched_columns}
    end
  end

  defp apply_auto_mapping(column, prefixed_attribute_to_dwc_field_mapping) do
    mapping =
      Enum.find(prefixed_attribute_to_dwc_field_mapping, fn {_, dwc_field} ->
        column.name == dwc_field
      end)

    %{column | mapped_to: Atom.to_string(elem(mapping, 0)), mapped?: true}
  end

  defp ensure_required_attributes(mapped_columns) do
    Enum.reduce(@mandatory_attributes, mapped_columns, fn mandatory_attribute, mapped_columns ->
      case Enum.find(mapped_columns, &(&1.mapped_to == mandatory_attribute)) do
        nil ->
          column = %Import.Column{
            mapped?: false,
            mapped_to: mandatory_attribute
          }

          [column | mapped_columns]

        _ ->
          mapped_columns
      end
    end)
  end

  defp assign_filter(socket, params \\ %{}) do
    filter = to_form(params, as: :filter)
    assign(socket, :filter, filter)
  end

  defp column_form_visible?(form, filter) do
    query = normalize_string(Form.input_value(filter, :query))

    [:name, :mapped_to]
    |> Enum.map(&Form.input_value(form, &1))
    |> Enum.map(&normalize_string/1)
    |> Enum.any?(&String.contains?(&1, query))
  end

  defp column_name_visible?(name, filter) do
    query = normalize_string(Form.input_value(filter, :query))
    name |> normalize_string() |> String.contains?(query)
  end

  defp normalize_string(value) do
    value
    |> to_string()
    |> String.downcase()
  end

  defp init(socket, import) do
    socket =
      socket
      |> assign_form()
      |> assign_available_columns(import)
      |> assign_available_attributes(import)
      |> assign(:invalid?, Enum.any?(import.missing_mappings))
      |> assign(:quick_start_error, nil)
      |> assign_filter()

    socket
  end

  defp assign_form(socket) do
    %{current_user: actor, import: import} = socket.assigns

    assign(socket, :form, build_form(import, actor))
  end

  defp build_form(import, actor) do
    import
    |> AshPhoenix.Form.for_update(
      :update_mapping,
      domain: DataAggregator.Records,
      as: "import",
      actor: actor,
      forms: [
        columns: [
          data: import.mappings,
          type: :list,
          resource: Import.Column,
          create_action: :create_mapping,
          update_action: :update_mapping
        ]
      ]
    )
    |> to_form()
  end

  # Calculates the available column names of the import.mapping as array of strings
  # and assigns them as :available_columns to the socket. This function is only
  # valid during the init phase and must NOT be used during the validate phase.
  @spec assign_available_columns(Socket.t(), Import.t()) :: Socket.t()
  defp assign_available_columns(socket, %Import{columns: columns, mappings: mappings}) do
    columns_in_use =
      mappings
      |> Enum.filter(&in_use?/1)
      |> Enum.map(& &1.name)

    assign_columns(socket, columns_in_use, columns)
  end

  # Update the available columns based on the form params (during validate phase
  # which is triggered by the phx-change event). In this case we can't start from
  # the import.mapping but need to iterate over all selected form columns and check
  # whether they are already in use.
  defp update_available_columns(socket, %{"columns" => columns}) do
    %{import: import} = socket.assigns

    columns_in_use =
      columns
      |> Enum.map(fn {_index, column} -> column["name"] end)
      |> Enum.reject(&(&1 == ""))

    assign_columns(socket, columns_in_use, import.columns)
  end

  defp update_available_columns(socket, _), do: socket

  defp assign_columns(socket, columns_in_use, columns) do
    available_columns =
      columns
      |> Enum.filter(&(&1.name not in columns_in_use))
      |> Enum.map(& &1.name)

    assign(socket, :available_columns, available_columns)
  end

  # A column is in use if it is mandatory and the name is not nil or
  # if it is optional and mapped? (mapped_to is not nil).
  defp in_use?(%Import.Column{} = column) do
    %Import.Column{mapped?: mapped?, name: name, mapped_to: mapped_to} = column

    (mandatory?(mapped_to) and not is_nil(name)) or (optional?(column) and mapped?)
  end

  # Calculates the available attributes of the import.mapping as a list of tuples
  # (category, attributes) and assigns them as :available_attributes to the socket.
  @spec assign_available_attributes(Socket.t(), Import.t()) :: Socket.t()
  defp assign_available_attributes(socket, %Import{mappings: mappings}) do
    attributes_in_use =
      mappings
      |> Enum.filter(& &1.mapped?)
      |> Enum.map(& &1.mapped_to)

    assign_attributes(socket, attributes_in_use)
  end

  # Update the available attributes based on the form params (during validate phase
  # which is triggered by the phx-change event). In this case we can't start from
  # the import.mapping but need to iterate over all selected form columns and check
  # whether they are already in use.
  defp update_available_attributes(socket, %{"columns" => columns}) do
    attributes_in_use =
      columns
      |> Enum.map(fn {_index, column} -> column["mapped_to"] end)
      |> Enum.reject(&blank?/1)
      |> Enum.map(&String.to_atom/1)

    assign_attributes(socket, attributes_in_use)
  end

  defp update_available_attributes(socket, _), do: socket

  defp assign_attributes(socket, attributes_in_use) do
    available_attributes =
      Enum.map(attribute_options(), fn {category, attribute_tuple} ->
        available_category_attributes =
          Enum.reject(attribute_tuple, fn {_, prefixed_attribute} ->
            Enum.member?(attributes_in_use, prefixed_attribute)
          end)

        {category, Enum.sort(available_category_attributes)}
      end)

    assign(socket, :available_attributes, Enum.sort(available_attributes))
  end

  defp name_for_value_or_values(form, field, values) when is_list(values) do
    Form.input_name(form, field) <> "[]"
  end

  defp name_for_value_or_values(form, field, _value) do
    Form.input_name(form, field)
  end

  defp mandatory?(%Form{} = form), do: mandatory?(Form.input_value(form, :mapped_to))
  defp mandatory?(mapped_to) when is_atom(mapped_to), do: mandatory?(Atom.to_string(mapped_to))
  defp mandatory?(mapped_to) when is_binary(mapped_to), do: mapped_to in @mandatory_attributes
  defp mandatory?(_), do: false

  defp optional?(val), do: not mandatory?(val)

  defp maybe_add_selected_column_name(%Form{} = form, available_columns) do
    name = Form.input_value(form, :name)

    if blank?(name) do
      available_columns
    else
      [name | available_columns]
    end
  end

  defp maybe_add_selected_attribute(%Form{} = form, options) do
    prefixed_attribute = Form.input_value(form, :mapped_to)
    category = prefixed_attribute_category(prefixed_attribute)

    # Always add the custom attribute option for the given column name
    options = [{"Custom Attribute", Form.input_value(form, :name)} | options]

    options =
      cond do
        blank?(prefixed_attribute) ->
          options

        is_nil(category) ->
          options

        true ->
          description = Map.fetch!(category, :description)

          attribute_name_without_prefix =
            DarwinCore.Schema.attribute_name_without_prefix(prefixed_attribute)

          attribute =
            Enum.find(category.dwc_attributes, fn dwc_attribute ->
              dwc_attribute.attribute.name == attribute_name_without_prefix
            end)

          insert_attribute(description, attribute.dwc_field, prefixed_attribute, options)
      end

    Enum.reject(options, fn {_, attrs} -> is_list(attrs) && Enum.empty?(attrs) end)
  end

  defp prefixed_attribute_category(nil), do: nil

  defp prefixed_attribute_category(prefixed_attribute) do
    category = DarwinCore.Schema.category_from_prefixed_attribute_name(prefixed_attribute)

    if is_nil(category) do
      category
    else
      case DarwinCore.Schema.category_label_by_description(category.description) do
        nil ->
          category

        label ->
          %{category | description: "#{label}: #{category.description}"}
      end
    end
  end

  defp insert_attribute(category, attribute, prefixed_attribute, options) do
    Enum.map(options, fn {desc, attrs} ->
      if desc == category do
        {desc, [{attribute, String.to_existing_atom(prefixed_attribute)} | attrs]}
      else
        {desc, attrs}
      end
    end)
  end

  defp mapping_valid?(%Import{mappings: mappings}) do
    Enum.all?(@mandatory_attributes, fn attribute ->
      Enum.any?(mappings, &(&1.mapped_to == attribute))
    end)
  end

  defp valid_links(collection, import, meta) do
    summary =
      if Enum.empty?(import.missing_mappings),
        do: build_path(~p"/datasets/#{collection}/imports/#{import}/summary", meta)

    [nil, nil, summary]
  end
end
