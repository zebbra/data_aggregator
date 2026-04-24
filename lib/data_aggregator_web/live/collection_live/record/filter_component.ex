defmodule DataAggregatorWeb.CollectionLive.Record.FilterComponent do
  @moduledoc false
  @behaviour DataAggregatorWeb.Filters

  use DataAggregatorWeb, :live_component
  use DataAggregatorWeb.Filters

  import DataAggregator.Helpers, only: [distinct_ecto: 3]

  alias AshPagify.FilterForm
  alias AshPhoenix.FilterForm.Predicate
  alias DataAggregator.Records.Record
  alias Phoenix.LiveView.AsyncResult

  require Ash.Query

  @impl true
  def mount(socket) do
    socket = assign(socket, :error, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    first_update_for_collection? =
      Map.get(socket.assigns, :loaded_collection_id) != assigns.collection.id

    socket =
      socket
      |> assign(assigns)
      |> assign_form()
      |> assign_collapsible_state()
      |> assign(:count, format_count(assigns.meta.total_count))
      |> assign(:label, Map.get(assigns, :label, ~t"entries"m))

    socket =
      if first_update_for_collection? do
        socket
        |> assign(:distinct_options, AsyncResult.loading())
        |> assign(:loaded_collection_id, assigns.collection.id)
        |> start_async_options()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.async_data :let={distinct_options} async_result={@distinct_options}>
        <:loading>
          <div class="space-y-6 p-6">
            <.skeleton class="h-5 w-1/4" />
            <.skeleton class="h-4 w-full" />
            <.skeleton class="h-4 w-5/6" />
            <.skeleton class="mt-8 h-5 w-1/4" />
            <.skeleton class="h-4 w-full" />
            <.skeleton class="h-4 w-4/5" />
            <.skeleton class="mt-8 h-5 w-1/4" />
            <.skeleton class="h-4 w-full" />
            <.skeleton class="h-4 w-5/6" />
          </div>
        </:loading>
        <:failed>
          <div class="flex p-6">
            <div class="mr-4 shrink-0">
              <.icon name="hero-x-circle-mini" class="size-6 text-error" />
            </div>
            <p class="text-sm">
              {~t"Failed to load filter options. Please close the modal and try again."m}
            </p>
          </div>
        </:failed>
        <.simple_filter_form
          filter_form={@filter_form}
          count={@count}
          label={@label}
          target={@myself}
          error={@error}
        >
          <:components :let={filter_form}>
            <.filter_form_component
              component={filter_form}
              resource={@meta.resource}
              collapsible_state={@collapsible_state}
              distinct_options={distinct_options}
              target={@myself}
            />
          </:components>
        </.simple_filter_form>
      </.async_data>
    </div>
    """
  end

  attr :component, :map, required: true, doc: "Could be a FilterForm (group) or a Predicate"
  attr :resource, :atom, required: true, doc: "The resource to filter"
  attr :collapsible_state, :map, required: true, doc: "The state of the collapsible components"

  attr :distinct_options, :map,
    default: %{},
    doc: "The map of list of options for the various select filters"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  # @impl true
  # def filter_form_component(%{component: %{source: %FilterForm{key: "eve_event_date_range"}}} = assigns) do
  #   ~H"""
  #   <div class="px-6">
  #     <.date_range
  #       component={@component}
  #       title={~t"Date"m}
  #       description={~t"Search your records by occurrence date"m}
  #       min_date={Cldr.Calendar.date_from_tuple({1800, 1, 1})}
  #       max_date={Cldr.Calendar.current(Date.utc_today(), :day)}
  #       presets={[
  #         months: ~t"Last Month"m,
  #         years: ~t"Last Year"m,
  #         century: ~t"Last Century"m
  #       ]}
  #       target={@target}
  #       top_level
  #     />
  #   </div>
  #   """
  # end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "taxonomy"}}} = assigns) do
    ~H"""
    <div class="pt-4">
      <.collapsible_group
        title={~t"Taxonomy"m}
        key="taxonomy"
        target={@target}
        open={open_collapsible?(@collapsible_state, "taxonomy")}
      >
        <.inputs_for :let={component} field={@component[:components]}>
          <.filter_form_component
            component={component}
            resource={@resource}
            collapsible_state={@collapsible_state}
            distinct_options={@distinct_options}
            target={@target}
          />
        </.inputs_for>
      </.collapsible_group>
    </div>
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :tax_scientific_name}}} = assigns) do
    ~H"""
    <.text_search
      component={@component}
      title={~t"Scientific Name"m}
      description={~t"Search your records by scientifc name"m}
      target={@target}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :tax_kingdom}}} = assigns) do
    ~H"""
    <.checkbox_group_filter
      component={@component}
      title={~t"Kingdom"m}
      target={@target}
      options={@distinct_options[:tax_kingdom]}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :tax_phylum}}} = assigns) do
    ~H"""
    <.combobox_group_filter
      component={@component}
      title={~t"Phylum"m}
      target={@target}
      options={@distinct_options[:tax_phylum]}
      legend_size="md"
      multiple
      data-portal="filters_modal"
      identificator="filter_tax_phylum"
      clear_event="filter_tax_phylum:reset"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :tax_family}}} = assigns) do
    ~H"""
    <.combobox_group_filter
      component={@component}
      title={~t"Family"m}
      target={@target}
      options={@distinct_options[:tax_family]}
      legend_size="md"
      multiple
      data-portal="filters_modal"
      identificator="filter_tax_family"
      clear_event="filter_tax_family:reset"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "date"}}} = assigns) do
    ~H"""
    <div class="pt-4">
      <.collapsible_group
        title={~t"Date"m}
        key="date"
        target={@target}
        open={open_collapsible?(@collapsible_state, "date")}
      >
        <.inputs_for :let={component} field={@component[:components]}>
          <.filter_form_component
            component={component}
            resource={@resource}
            collapsible_state={@collapsible_state}
            distinct_options={@distinct_options}
            target={@target}
          />
        </.inputs_for>
      </.collapsible_group>
    </div>
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "updated_at_range"}}} = assigns) do
    ~H"""
    <.date_range
      component={@component}
      title={~t"Last modified"m}
      description={~t"Search your records by last modification date"m}
      min_date={Cldr.Calendar.date_from_tuple({1800, 1, 1})}
      max_date={Cldr.Calendar.next(Date.utc_today(), :day)}
      presets={[
        months: ~t"Last Month"m,
        years: ~t"Last Year"m,
        century: ~t"Last Century"m
      ]}
      target={@target}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "year_range"}}} = assigns) do
    ~H"""
    <.integer_range
      component={@component}
      title={~t"Year of event"m}
      description={
        ~t"The four-digit year in which the dwc:Event occurred, according to the Common Era Calendar"m
      }
      min_int={1600}
      max_int={Cldr.Calendar.next(Date.utc_today(), :day).year}
      target={@target}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :eve_event_date_presence}}} = assigns) do
    ~H"""
    <.radio_group_filter
      component={@component}
      title={~t"Event Date"m}
      description={~t"Look for species with or without and event date"m}
      target={@target}
      options={[
        [key: ~t"Any"m, value: ""],
        [key: ~t"Present"m, value: "true"],
        [key: ~t"Absent"m, value: "false"]
      ]}
      option_descriptions={
        %{
          "true" => ~t"Species for which an event date is present"m,
          "false" => ~t"Species without an event date"m
        }
      }
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "location"}}} = assigns) do
    ~H"""
    <div class="pt-4">
      <.collapsible_group
        title={~t"Location"m}
        key="location"
        target={@target}
        open={open_collapsible?(@collapsible_state, "location")}
        border_bottom={true}
      >
        <.inputs_for :let={component} field={@component[:components]}>
          <.filter_form_component
            component={component}
            resource={@resource}
            collapsible_state={@collapsible_state}
            distinct_options={@distinct_options}
            target={@target}
          />
        </.inputs_for>
      </.collapsible_group>
    </div>
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_continent}}} = assigns) do
    ~H"""
    <.checkbox_group_filter
      component={@component}
      title={~t"Continent"m}
      target={@target}
      options={@distinct_options[:loc_continent]}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_country}}} = assigns) do
    ~H"""
    <.combobox_group_filter
      component={@component}
      title={~t"Country"m}
      target={@target}
      options={@distinct_options[:loc_country]}
      legend_size="md"
      multiple
      data-portal="filters_modal"
      identificator="filter_loc_country"
      clear_event="filter_loc_country:reset"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_state_province}}} = assigns) do
    ~H"""
    <.combobox_group_filter
      component={@component}
      title={~t"State Province"m}
      target={@target}
      options={@distinct_options[:loc_state_province]}
      legend_size="md"
      multiple
      data-portal="filters_modal"
      identificator="filter_loc_state_province"
      clear_event="filter_loc_state_province:reset"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_locality}}} = assigns) do
    ~H"""
    <.text_search
      component={@component}
      title={~t"Locality"m}
      description={~t"Search your records by locality"m}
      target={@target}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_decimal_presence}}} = assigns) do
    ~H"""
    <.radio_group_filter
      component={@component}
      title={~t"Decimal Coordinates"m}
      description={~t"Search for records with or without decimal coordinates"m}
      target={@target}
      options={[
        [key: ~t"Any"m, value: ""],
        [key: ~t"Present"m, value: "true"],
        [key: ~t"Absent"m, value: "false"]
      ]}
      option_descriptions={
        %{
          "true" => ~t"Species for which decimal coordinates are present"m,
          "false" => ~t"Species for which decimal coordinates are absent"m
        }
      }
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_swiss_coordinates_95_presence}}} = assigns) do
    ~H"""
    <.radio_group_filter
      component={@component}
      title={~t"Swiss 95 Coordinates"m}
      description={~t"Search for records with or without swiss 95 coordinates"m}
      target={@target}
      options={[
        [key: ~t"Any"m, value: ""],
        [key: ~t"Present"m, value: "true"],
        [key: ~t"Absent"m, value: "false"]
      ]}
      option_descriptions={
        %{
          "true" => ~t"Species for which swiss 95 coordinates are present"m,
          "false" => ~t"Species for which swiss 95 coordinates are absent"m
        }
      }
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :loc_swiss_coordinates_03_presence}}} = assigns) do
    ~H"""
    <.radio_group_filter
      component={@component}
      title={~t"Swiss 03 Coordinates"m}
      description={~t"Search for records with or without swiss 03 coordinates"m}
      target={@target}
      options={[
        [key: ~t"Any"m, value: ""],
        [key: ~t"Present"m, value: "true"],
        [key: ~t"Absent"m, value: "false"]
      ]}
      option_descriptions={
        %{
          "true" => ~t"Species for which swiss 03 coordinates are present"m,
          "false" => ~t"Species for which swiss 03 coordinates are absent"m
        }
      }
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "other"}}} = assigns) do
    ~H"""
    <div class="py-4">
      <.collapsible_group
        title={~t"Other"m}
        key="other"
        target={@target}
        open={open_collapsible?(@collapsible_state, "other")}
        border_bottom={false}
      >
        <.inputs_for :let={component} field={@component[:components]}>
          <.filter_form_component
            component={component}
            resource={@resource}
            collapsible_state={@collapsible_state}
            distinct_options={@distinct_options}
            target={@target}
          />
        </.inputs_for>
      </.collapsible_group>
    </div>
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :iucn_redlist_category_group}}} = assigns) do
    ~H"""
    <.radio_group_filter
      component={@component}
      title={~t"IUCN Red List"m}
      description={~t"Search your records by IUCN Red List of Threatened Speciese"m}
      target={@target}
      options={[
        [key: ~t"Any"m, value: ""],
        [key: ~t"Threatened"m, value: "threatened"],
        [key: ~t"Less threatened"m, value: "less_threatened"],
        [key: ~t"Extinct (or nearly)"m, value: "extinct"],
        [key: ~t"Uncertain data"m, value: "uncertain_data"]
      ]}
      option_descriptions={
        %{
          "threatened" => ~t"Threatened species according to IUCN Red List"m,
          "less_threatened" => ~t"Less threatened species according to IUCN Red List"m,
          "extinct" => ~t"Extinct (or nearly) species according to IUCN Red List"m,
          "uncertain_data" => ~t"Insufficient data for IUCN classification"m
        }
      }
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :mids_level}}} = assigns) do
    ~H"""
    <.radio_group_filter
      component={@component}
      title={~t"Mids Level"m}
      description={~t"Search your records by data mids level"m}
      target={@target}
      options={[
        [key: ~t"Any"m, value: ""],
        [key: 0, value: "1"],
        [key: 1, value: "2"],
        [key: 2, value: "3"],
        [key: 3, value: "4"]
      ]}
      option_descriptions={
        %{
          "1" => ~t"Records with a Mids Level of at least 0"m,
          "2" => ~t"Records with a Mids Level of at least 1"m,
          "3" => ~t"Records with a Mids Level of at least 2"m,
          "4" => ~t"Records with a Mids Level of at least 3"m
        }
      }
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :mte_recorded_by}}} = assigns) do
    ~H"""
    <.text_search
      component={@component}
      title={~t"Recorded By"m}
      description={~t"Search your records by the person(s) which recorded the occurrence first"m}
      target={@target}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :idf_type_status}}} = assigns) do
    ~H"""
    <.checkbox_group_filter
      component={@component}
      title={~t"Type Status"m}
      target={@target}
      options={@distinct_options[:idf_type_status]}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :mts_material_sample_type}}} = assigns) do
    ~H"""
    <.checkbox_group_filter
      component={@component}
      title={~t"Material Sample Type"m}
      target={@target}
      options={@distinct_options[:mts_material_sample_type]}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :mte_preparations}}} = assigns) do
    ~H"""
    <.checkbox_group_filter
      component={@component}
      title={~t"Preparations"m}
      target={@target}
      options={@distinct_options[:mte_preparations]}
      legend_size="md"
    />
    """
  end

  # Default implementation for groups
  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{}}} = assigns) do
    ~H"""
    <.inputs_for :let={component} field={@component[:components]}>
      <.filter_form_component
        component={component}
        resource={@resource}
        collapsible_state={@collapsible_state}
        distinct_options={@distinct_options}
        target={@target}
      />
    </.inputs_for>
    """
  end

  # Default implementation for predicates
  @impl true
  def filter_form_component(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.input type="hidden" field={@component[:field]} />
    <.input type="hidden" field={@component[:operator]} />
    <.input type="hidden" field={@component[:path]} />
    <.input type="hidden" field={@component[:value]} />
    """
  end

  @impl true
  def init_form(resource) do
    resource
    |> FilterForm.new()
    # Remove for now as we use strings in our database...
    # |> FilterForm.add_group(return_id?: true, key: "eve_event_date_range")
    # |> then(fn {form, date_range_group_id} ->
    #   form
    #   |> FilterForm.add_predicate(:eve_event_date, :greater_than_or_equal, nil, to: date_range_group_id)
    #   |> FilterForm.add_predicate(:eve_event_date, :less_than_or_equal, nil, to: date_range_group_id)
    # end)
    |> FilterForm.add_group(return_id?: true, key: "taxonomy")
    |> then(fn {form, taxonomy_group_id} ->
      form
      |> FilterForm.add_predicate(:tax_scientific_name, :contains, nil,
        to: taxonomy_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:tax_kingdom, :in, [],
        to: taxonomy_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:tax_phylum, :in, [],
        to: taxonomy_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:tax_family, :in, [],
        to: taxonomy_group_id,
        path: "encoded_record"
      )
    end)
    |> FilterForm.add_group(return_id?: true, key: "date")
    |> then(fn {form, date_group_id} ->
      form
      |> FilterForm.add_group(return_id?: true, key: "updated_at_range", to: date_group_id)
      |> then(fn {form, date_group_id} ->
        form
        |> FilterForm.add_predicate(:updated_at, :greater_than_or_equal, "",
          to: date_group_id,
          path: "encoded_record"
        )
        |> FilterForm.add_predicate(:updated_at, :less_than_or_equal, "",
          to: date_group_id,
          path: "encoded_record"
        )
      end)
      |> FilterForm.add_group(return_id?: true, key: "year_range", to: date_group_id)
      |> then(fn {form, year_range_group_id} ->
        form
        |> FilterForm.add_predicate(:eve_year, :greater_than_or_equal, "",
          to: year_range_group_id,
          path: "encoded_record"
        )
        |> FilterForm.add_predicate(:eve_year, :less_than_or_equal, "",
          to: year_range_group_id,
          path: "encoded_record"
        )
      end)
      |> FilterForm.add_predicate(:eve_event_date_presence, :eq, "", to: date_group_id)
    end)
    |> FilterForm.add_group(return_id?: true, key: "location")
    |> then(fn {form, location_group_id} ->
      form
      |> FilterForm.add_predicate(:loc_continent, :in, [],
        to: location_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:loc_country, :in, [],
        to: location_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:loc_state_province, :in, [],
        to: location_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:loc_locality, :contains, nil,
        to: location_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:loc_decimal_presence, :eq, "", to: location_group_id)
      |> FilterForm.add_predicate(:loc_swiss_coordinates_95_presence, :eq, "", to: location_group_id)
      |> FilterForm.add_predicate(:loc_swiss_coordinates_03_presence, :eq, "", to: location_group_id)
    end)
    |> FilterForm.add_group(return_id?: true, key: "other", operator: :or)
    |> then(fn {form, other_group_id} ->
      form
      |> FilterForm.add_predicate(:iucn_redlist_category_group, :eq, "", to: other_group_id)
      |> FilterForm.add_predicate(:mids_level, :greater_than_or_equal, "", to: other_group_id)
      |> FilterForm.add_predicate(:mte_recorded_by, :contains, nil,
        to: other_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:idf_type_status, :in, [],
        to: other_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:mts_material_sample_type, :in, [],
        to: other_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:mte_preparations, :in, [],
        to: other_group_id,
        path: "encoded_record"
      )
    end)
  end

  # @impl true
  # def handle_preset(filter_form, "eve_event_date_range", preset, socket) do
  #   filter_form =
  #     FilterForm.update_group(filter_form, "eve_event_date_range", fn predicate ->
  #       case predicate.operator do
  #         :greater_than_or_equal ->
  #           %{predicate | value: shift_date(preset)}

  #         :less_than_or_equal ->
  #           %{predicate | value: Date.utc_today()}
  #       end
  #     end)

  #   assign_and_update(socket, filter_form)
  # end

  @impl true
  def handle_preset(filter_form, "updated_at_range", preset, socket) do
    filter_form =
      FilterForm.update_group(filter_form, "updated_at_range", fn predicate ->
        case [predicate.field, predicate.operator] do
          [:updated_at, :greater_than_or_equal] ->
            %{predicate | value: shift_date(preset)}

          [:updated_at, :less_than_or_equal] ->
            %{predicate | value: Date.add(Date.utc_today(), 1)}

          _ ->
            predicate
        end
      end)

    assign_and_update(socket, filter_form)
  end

  @impl true
  def handle_preset(_filter_form, _key, _preset, socket) do
    {:noreply, socket}
  end

  @impl true
  def update_count(%{assigns: %{filter_form: %{valid?: false}}} = socket, _params, _reset) do
    socket
  end

  @impl true
  def update_count(socket, filter_form_params, reset) do
    %{collection: collection, meta: meta} = socket.assigns

    query = Ash.Query.set_tenant(Record, collection)

    count = FilterForm.count(meta, filter_form_params, reset, query)

    assign(socket, :count, format_count(count))
  rescue
    _ ->
      filter_form = init_form(socket.assigns.meta.resource)

      socket
      |> assign(:filter_form, filter_form)
      |> assign(:error, ~t"Something went wrong, please try again.")
  end

  @impl true
  def handle_event("filter_tax_family:reset", %{"predicate-id" => predicate_id}, socket) do
    filter_form = socket.assigns.filter_form

    filter_form =
      FilterForm.update_predicate(filter_form, predicate_id, fn predicate ->
        %{predicate | value: ""}
      end)

    # force combobox to reset
    socket =
      push_event(socket, "combobox:reset", %{name: "filter_tax_family"})

    assign_and_update(socket, filter_form)
  end

  @impl true
  def handle_event("filter_tax_phylum:reset", %{"predicate-id" => predicate_id}, socket) do
    filter_form = socket.assigns.filter_form

    filter_form =
      FilterForm.update_predicate(filter_form, predicate_id, fn predicate ->
        %{predicate | value: ""}
      end)

    # force combobox to reset
    socket =
      push_event(socket, "combobox:reset", %{name: "filter_tax_phylum"})

    assign_and_update(socket, filter_form)
  end

  @impl true
  def handle_event("filter_loc_country:reset", %{"predicate-id" => predicate_id}, socket) do
    filter_form = socket.assigns.filter_form

    filter_form =
      FilterForm.update_predicate(filter_form, predicate_id, fn predicate ->
        %{predicate | value: ""}
      end)

    # force combobox to reset
    socket =
      push_event(socket, "combobox:reset", %{name: "filter_loc_country"})

    assign_and_update(socket, filter_form)
  end

  @impl true
  def handle_event("filter_loc_state_province:reset", %{"predicate-id" => predicate_id}, socket) do
    filter_form = socket.assigns.filter_form

    filter_form =
      FilterForm.update_predicate(filter_form, predicate_id, fn predicate ->
        %{predicate | value: ""}
      end)

    # force combobox to reset
    socket =
      push_event(socket, "combobox:reset", %{name: "filter_loc_state_province"})

    assign_and_update(socket, filter_form)
  end

  defp assign_collapsible_state(socket) do
    active_filter_form_fields = FilterForm.active_filter_form_fields(socket.assigns.meta)

    active_taxonomy =
      Enum.any?(
        ~w[tax_scientific_name tax_kingdom tax_phylum tax_family],
        &(&1 in active_filter_form_fields)
      )

    active_date =
      Enum.any?(
        ~w[updated_at eve_year eve_event_date_presence],
        &(&1 in active_filter_form_fields)
      )

    active_location =
      Enum.any?(
        ~w[loc_continent loc_country loc_locality loc_decimal_presence loc_swiss_coordinates_95_presence loc_swiss_coordinates_03_presence],
        &(&1 in active_filter_form_fields)
      )

    active_others =
      Enum.any?(
        ~w[iucn_redlist_category_group mids_level mte_recorded_by idf_type_status mts_material_sample_type mte_preparations],
        &(&1 in active_filter_form_fields)
      )

    assign(socket, :collapsible_state, %{
      "taxonomy" => active_taxonomy,
      "date" => active_date,
      "location" => active_location,
      "other" => active_others
    })
  end

  defp open_collapsible?(collapsible_state, key) do
    Map.get(collapsible_state, key, false)
  end

  defp start_async_options(socket) do
    collection = socket.assigns.collection

    assign_async(socket, :distinct_options, fn -> load_options(collection) end)
  end

  defp load_options(collection) do
    fields = [
      :loc_continent,
      :loc_country,
      :loc_state_province,
      :idf_type_status,
      :mts_material_sample_type,
      :mte_preparations,
      :tax_kingdom,
      :tax_phylum,
      :tax_family
    ]

    results =
      fields
      |> Enum.map(&fn -> distinct_ecto(&1, :encoded_records, collection) end)
      |> Task.async_stream(& &1.(), ordered: true, timeout: to_timeout(second: 30))
      |> Enum.map(fn {:ok, result} -> result end)

    {:ok, %{distinct_options: Map.new(Enum.zip(fields, results))}}
  end
end
