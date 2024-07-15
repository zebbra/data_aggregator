defmodule DataAggregatorWeb.Filters do
  @moduledoc """
  This module provides a simple way to create a filter form for different types of data.

  ## Introduction

  Filters are built in conjunction with the `Pagify.FilterForm` module and the
  `DataAggregatorWeb.Components` library. This module provides filters for different
  types of data, such as date ranges, text search, select, radio and checkbox groups
  filters.

  ## Usage

  To use this module, you need to import it in your LiveView module and use the
  `use DataAggregatorWeb.Filters` macro. This will import all the necessary functions
  and modules to create a filter form.

  To enforce the implementation of the `filter_form_component/1`, `init_form/1`,
  `handle_preset/4` and `update_count/3` callbacks, you should use the
  `@behaviour DataAggregatorWeb.Filters` macro.

  You have to at least add the default `filter_form_component/1` implementations
  for `AshPhoenix.FilterForm.Predicate` and `Pagify.FilterForm`. See below for an example.
  The easiest way is to simply copy&paste the code below into your LiveView module.

  Then you can add your custom filter components by implementing the `filter_form_component/1`
  and match them with the `source` field of the `AshPhoenix.FilterForm.Predicate` or
  `Pagify.FilterForm` struct.

  ## Example

  ```elixir
  defmodule DataAggregatorWeb.Live.Dashboard do
    @behaviour DataAggregatorWeb.Filters

    use DataAggregatorWeb, :live_view
    use DataAggregatorWeb.Filters

    import DataAggregator.Helpers, only: [distinct: 2]

    alias AshPhoenix.FilterForm.Predicate
    alias DataAggregator.Records.EncodedRecord
    alias DataAggregator.Records.Record
    alias Pagify.FilterForm

    @impl true
    def mount(socket) do
      distinct_options = %{
        loc_continent: loc_continent_options(),
        tax_kingdom: tax_kingdom_options(),
        tax_phylum: tax_phylum_options()
      }

      socket =
        socket
        |> assign(:distinct_options, distinct_options)
        |> assign(:error, nil)

      {:ok, socket}
    end

    @impl true
    def update(assigns, socket) do
      socket =
        socket
        |> assign(assigns)
        |> assign_form()
        |> assign_collapsible_state()
        |> assign(:count, format_count(assigns.meta.total_count))
        |> assign(:label, Map.get(assigns, :label, ~t"entries"m))

      {:ok, socket}
    end

    @impl true
    def render(assigns) do
      ~H\"""
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
      \"""
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
      ~H\"""
      <div class="px-6">
        <.radio_group
          component={@component}
          title={~t"IUCN Red List"m}
          description={~t"Search your records by IUCN Red List of Threatened Speciese"m}
          target={@target}
          options={[
            [key: ~t"Any"m, value: ""],
            [key: ~t"Endangered"m, value: "true"],
            [key: ~t"Safe"m, value: "false"]
          ]}
          top_level
        />
      </div>
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %FilterForm{key: "eve_event_date_range"}}} = assigns) do
      ~H\"""
      <div class="px-6">
        <.date_range
          component={@component}
          title={~t"Date"m}
          description={~t"Search your records by occurrence date"m}
          min_date={Cldr.Calendar.date_from_tuple({1800, 1, 1})}
          max_date={Cldr.Calendar.current(Date.utc_today(), :day)}
          presets={[
            months: ~t"Last Month"m,
            years: ~t"Last Year"m,
            century: ~t"Last Century"m
          ]}
          target={@target}
          top_level
        />
      </div>
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %FilterForm{key: "taxonomy"}}} = assigns) do
      ~H\"""
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
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %Predicate{field: :tax_scientific_name}}} = assigns) do
      ~H\"""
      <.text_search
        component={@component}
        title={~t"Scientific Name"m}
        description={~t"Search your records by scientifc name"m}
        target={@target}
        legend_size="md"
      />
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %Predicate{field: :tax_kingdom}}} = assigns) do
      ~H\"""
      <.checkbox_group
        component={@component}
        title={~t"Kingdom"m}
        target={@target}
        options={@distinct_options[:tax_kingdom]}
        legend_size="md"
      />
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %Predicate{field: :tax_phylum}}} = assigns) do
      ~H\"""
      <.checkbox_group
        component={@component}
        title={~t"Phylum"m}
        target={@target}
        options={@distinct_options[:tax_phylum]}
        legend_size="md"
      />
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %FilterForm{key: "location"}}} = assigns) do
      ~H\"""
      <div class="py-4">
        <.collapsible_group
          title={~t"Location"m}
          key="location"
          target={@target}
          open={open_collapsible?(@collapsible_state, "location")}
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
      \"""
    end

    @impl true
    def filter_form_component(%{component: %{source: %Predicate{field: :loc_continent}}} = assigns) do
      ~H\"""
      <.checkbox_group
        component={@component}
        title={~t"Continent"m}
        target={@target}
        options={@distinct_options[:loc_continent]}
        legend_size="md"
      />
      \"""
    end

    # Default implementation for groups
        @impl true
    def filter_form_component(%{component: %{source: %FilterForm{}}} = assigns) do
      ~H\"""
      <.inputs_for :let={component} field={@component[:components]}>
        <.filter_form_component
          component={component}
          resource={@resource}
          collapsible_state={@collapsible_state}
          distinct_options={@distinct_options}
          target={@target}
        />
      </.inputs_for>
      \"""
    end

    # Default implementation for predicates
    @impl true
    def filter_form_component(%{component: %{source: %Predicate{}}} = assigns) do
      ~H\"""
      <.input type="hidden" field={@component[:field]} />
      <.input type="hidden" field={@component[:operator]} />
      <.input type="hidden" field={@component[:path]} />
      <.input type="hidden" field={@component[:value]} />
      \"""
    end

    @impl true
    def init_form(resource) do
      resource
      |> FilterForm.new()
      |> FilterForm.add_predicate(:iucn_redlist, :eq, "")
      |> FilterForm.add_group(return_id?: true, key: "eve_event_date_range")
      |> then(fn {form, date_range_group_id} ->
        form
        |> FilterForm.add_predicate(:eve_event_date, :greater_than_or_equal, nil, to: date_range_group_id)
        |> FilterForm.add_predicate(:eve_event_date, :less_than_or_equal, nil, to: date_range_group_id)
      end)
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
      end)
      |> FilterForm.add_group(return_id?: true, key: "location")
      |> then(fn {form, location_group_id} ->
        FilterForm.add_predicate(form, :loc_continent, :in, [],
          to: location_group_id,
          path: "encoded_record"
        )
      end)
    end

    @impl true
    def handle_preset(filter_form, "eve_event_date_range", preset, socket) do
      filter_form =
        FilterForm.update_group(filter_form, "eve_event_date_range", fn predicate ->
          case predicate.operator do
            :greater_than_or_equal ->
              %{predicate | value: shift_date(preset)}

            :less_than_or_equal ->
              %{predicate | value: Date.utc_today()}
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
      %{collection_id: collection_id, meta: meta} = socket.assigns

      query = Record.query_to_by_collection(collection_id)
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
      active_filter_form_fields = Pagify.active_filter_form_fields(socket.assigns.meta)

      active_taxonomy =
        Enum.any?(
          ~w[tax_scientific_name tax_kingdom tax_phylum],
          &(&1 in active_filter_form_fields)
        )

      active_location = Enum.any?(~w[loc_continent], &(&1 in active_filter_form_fields))

      assign(socket, :collapsible_state, %{
        "taxonomy" => active_taxonomy,
        "location" => active_location
      })
    end

    defp open_collapsible?(collapsible_state, key) do
      Map.get(collapsible_state, key, false)
    end

    defp loc_continent_options do
      distinct(EncodedRecord, :loc_continent)
    end

    defp tax_kingdom_options do
      distinct(EncodedRecord, :tax_kingdom)
    end

    defp tax_phylum_options do
      distinct(EncodedRecord, :tax_phylum)
    end
  end
  ```
  """

  alias Pagify.FilterForm

  @callback filter_form_component(assigns :: Phoenix.LiveView.Socket.assigns()) ::
              Phoenix.LiveView.Rendered.t()
  @callback init_form(resource :: :term) :: FilterForm.t()
  @callback handle_preset(
              filter_form :: FilterForm.t(),
              key :: String.t(),
              preset :: String.t(),
              socket :: Phoenix.LiveView.Socket.t()
            ) :: {:noreply, Phoenix.LiveView.Socket.t()}
  @callback update_count(
              socket :: Phoenix.LiveView.Socket.t(),
              filter_form_params :: map(),
              reset :: boolean
            ) :: Phoenix.LiveView.Socket.t()

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Filters.CheckboxGroup
      import DataAggregatorWeb.Filters.CollapsibleGroup
      import DataAggregatorWeb.Filters.ComboboxGroup
      import DataAggregatorWeb.Filters.DateRange
      import DataAggregatorWeb.Filters.Helpers
      import DataAggregatorWeb.Filters.RadioGroup
      import DataAggregatorWeb.Filters.SimpleFilterForm
      import DataAggregatorWeb.Filters.TextSearch

      @impl true
      def handle_event("collapsible_state:toggle", %{"key" => key}, socket) do
        collapsible_state = socket.assigns.collapsible_state
        collapsible_state = Map.update(collapsible_state, key, false, &(!&1))

        socket
        |> assign(:collapsible_state, collapsible_state)
        |> noreply()
      end

      @impl true
      def handle_event("filter_form:submit", %{"filter" => params}, socket) do
        %{filter_form: filter_form, path: path, meta: meta} = socket.assigns
        filter_form = FilterForm.validate(filter_form, params)

        if filter_form.valid? do
          filter_form_params =
            FilterForm.params_for_query(filter_form)

          meta = Pagify.set_filter_form(meta, filter_form_params)
          path = build_path(path, meta)

          send(self(), {"filter_form:submit", meta})

          socket
          |> push_event("submit:close", %{})
          |> push_patch(to: path)
          |> noreply()
        else
          socket
          |> assign(:filter_form, filter_form)
          |> assign(:error, ~t"Please review the form and try again")
          |> noreply()
        end
      end

      @impl true
      def handle_event("filter_form:validate", %{"filter" => params}, socket) do
        filter_form = socket.assigns.filter_form
        filter_form = FilterForm.validate(filter_form, params)

        assign_and_update(socket, filter_form)
      end

      @impl true
      def handle_event("filter_form:reset", _, socket) do
        filter_form = init_form(socket.assigns.meta.resource)

        assign_and_update(socket, filter_form, true)
      end

      @impl true
      def handle_event("filter_predicate:reset", %{"predicate-id" => predicate_id}, socket) do
        filter_form = socket.assigns.filter_form

        filter_form =
          FilterForm.update_predicate(filter_form, predicate_id, fn predicate ->
            %{predicate | value: ""}
          end)

        assign_and_update(socket, filter_form)
      end

      @impl true
      def handle_event("filter_group:preset", %{"key" => key, "preset" => preset}, socket) do
        handle_preset(socket.assigns.filter_form, key, preset, socket)
      end

      @impl true
      def handle_event("filter_group:reset", %{"key" => key}, socket) do
        filter_form = socket.assigns.filter_form

        filter_form =
          FilterForm.update_group(filter_form, key, fn predicate ->
            %{predicate | value: nil}
          end)

        assign_and_update(socket, filter_form)
      end

      defp assign_and_update(socket, filter_form, reset \\ false) do
        socket
        |> assign(:filter_form, filter_form)
        |> assign(:error, nil)
        |> update_count(FilterForm.params_for_query(filter_form), reset)
        |> noreply()
      end

      defp assign_form(socket) do
        %{meta: %{pagify: %{filter_form: params}, resource: resource}} = socket.assigns
        filter_form = FilterForm.new(resource, params: params, initial_form: init_form(resource))

        assign(socket, :filter_form, filter_form)
      end
    end
  end
end
