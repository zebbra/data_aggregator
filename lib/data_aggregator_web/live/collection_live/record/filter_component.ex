defmodule DataAggregatorWeb.CollectionLive.Record.FilterComponent do
  @moduledoc false
  @behaviour DataAggregatorWeb.Filters

  use DataAggregatorWeb, :live_component
  use DataAggregatorWeb.Filters

  import DataAggregator.Helpers, only: [distinct_ecto: 3]

  alias AshPagify.FilterForm
  alias AshPhoenix.FilterForm.Predicate
  alias DataAggregator.Records.Record

  require Ash.Query

  @impl true
  def mount(socket) do
    socket = assign(socket, :error, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()
      |> assign_collapsible_state()
      |> assign_options()
      |> assign(:count, format_count(assigns.meta.total_count))
      |> assign(:label, Map.get(assigns, :label, ~t"entries"m))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
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
            distinct_options={@distinct_options}
            target={@myself}
          />
        </:components>
      </.simple_filter_form>
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

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :iucn_redlist}}} = assigns) do
    ~H"""
    <div class="px-6">
      <.radio_group_filter
        component={@component}
        title={~t"IUCN Red List"m}
        description={~t"Search your records by IUCN Red List of Threatened Speciese"m}
        target={@target}
        options={[
          [key: ~t"Any"m, value: ""],
          [key: ~t"Endangered"m, value: "true"],
          [key: ~t"Safe"m, value: "false"]
        ]}
        option_descriptions={
          %{
            "true" => ~t"Endangered species according to IUCN Red List"m,
            "false" => ~t"Safe species according to IUCN Red List"m
          }
        }
        top_level
      />
    </div>
    """
  end

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
  def filter_form_component(%{component: %{source: %Predicate{field: :mids_level}}} = assigns) do
    ~H"""
    <div class="px-6">
      <.radio_group_filter
        component={@component}
        title={~t"Mids Level"m}
        description={~t"Search your records by data mids level"m}
        target={@target}
        options={[
          [key: ~t"Any"m, value: ""],
          [key: 1, value: "1"],
          [key: 2, value: "2"],
          [key: 3, value: "3"],
          [key: 4, value: "4"]
        ]}
        option_descriptions={
          %{
            "1" => ~t"Records with a Mids Level of at least 1"m,
            "2" => ~t"Records with a Mids Level of at least 2"m,
            "3" => ~t"Records with a Mids Level of at least 3"m,
            "4" => ~t"Records with a Mids Level of at least 4"m
          }
        }
        pills
        top_level
      />
    </div>
    """
  end

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
    <.checkbox_group_filter
      component={@component}
      title={~t"Phylum"m}
      target={@target}
      options={@distinct_options[:tax_phylum]}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %Predicate{field: :tax_family}}} = assigns) do
    ~H"""
    <.checkbox_group_filter
      component={@component}
      title={~t"Family"m}
      target={@target}
      options={@distinct_options[:tax_family]}
      legend_size="md"
    />
    """
  end

  @impl true
  def filter_form_component(%{component: %{source: %FilterForm{key: "location"}}} = assigns) do
    ~H"""
    <div class="py-4">
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
    |> FilterForm.add_predicate(:iucn_redlist, :eq, "")
    # Remove for now as we use strings in our database...
    # |> FilterForm.add_group(return_id?: true, key: "eve_event_date_range")
    # |> then(fn {form, date_range_group_id} ->
    #   form
    #   |> FilterForm.add_predicate(:eve_event_date, :greater_than_or_equal, nil, to: date_range_group_id)
    #   |> FilterForm.add_predicate(:eve_event_date, :less_than_or_equal, nil, to: date_range_group_id)
    # end)
    |> FilterForm.add_predicate(:mids_level, :greater_than_or_equal, "")
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
    |> FilterForm.add_group(return_id?: true, key: "location")
    |> then(fn {form, location_group_id} ->
      form
      |> FilterForm.add_predicate(:loc_continent, :in, [],
        to: location_group_id,
        path: "encoded_record"
      )
      |> FilterForm.add_predicate(:loc_locality, :contains, nil,
        to: location_group_id,
        path: "encoded_record"
      )
    end)
    |> FilterForm.add_group(return_id?: true, key: "other", operator: :or)
    |> then(fn {form, other_group_id} ->
      form
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

  defp assign_collapsible_state(socket) do
    active_filter_form_fields = FilterForm.active_filter_form_fields(socket.assigns.meta)

    active_taxonomy =
      Enum.any?(
        ~w[tax_scientific_name tax_kingdom tax_phylum tax_family],
        &(&1 in active_filter_form_fields)
      )

    active_location =
      Enum.any?(~w[loc_continent loc_locality], &(&1 in active_filter_form_fields))

    active_others =
      Enum.any?(
        ~w[mte_recorded_by idf_type_status mts_material_sample_type mte_preparations],
        &(&1 in active_filter_form_fields)
      )

    assign(socket, :collapsible_state, %{
      "taxonomy" => active_taxonomy,
      "location" => active_location,
      "other" => active_others
    })
  end

  defp open_collapsible?(collapsible_state, key) do
    Map.get(collapsible_state, key, false)
  end

  defp assign_options(socket) do
    assign_new(socket, :distinct_options, fn ->
      %{
        loc_continent: loc_continent_options(socket.assigns.collection),
        idf_type_status: idf_type_status_options(socket.assigns.collection),
        mts_material_sample_type: mts_material_sample_type_options(socket.assigns.collection),
        mte_preparations: mte_preparations_options(socket.assigns.collection),
        tax_kingdom: tax_kingdom_options(socket.assigns.collection),
        tax_phylum: tax_phylum_options(socket.assigns.collection),
        tax_family: tax_family_options(socket.assigns.collection)
      }
    end)
  end

  defp loc_continent_options(collection) do
    distinct_ecto(:loc_continent, :encoded_records, collection)
  end

  defp idf_type_status_options(collection) do
    distinct_ecto(:idf_type_status, :encoded_records, collection)
  end

  defp mts_material_sample_type_options(collection) do
    distinct_ecto(:mts_material_sample_type, :encoded_records, collection)
  end

  defp mte_preparations_options(collection) do
    distinct_ecto(:mte_preparations, :encoded_records, collection)
  end

  defp tax_kingdom_options(collection) do
    distinct_ecto(:tax_kingdom, :encoded_records, collection)
  end

  defp tax_phylum_options(collection) do
    distinct_ecto(:tax_phylum, :encoded_records, collection)
  end

  defp tax_family_options(collection) do
    distinct_ecto(:tax_family, :encoded_records, collection)
  end
end
