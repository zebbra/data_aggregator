defmodule DataAggregatorWeb.CollectionLive.Record.FilterComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  import DataAggregator.Helpers, only: [distinct: 2]

  alias AshPhoenix.FilterForm.Predicate
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record
  alias Pagify.FilterForm

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()
      |> assign_collapsible_state()
      |> format_count(assigns.meta.total_count)
      |> assign(:label, Map.get(assigns, :label, ~t"entries"m))
      |> assign(:error, nil)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <div :if={@error} class="px-6 pt-8">
        <.collapsible_notification title="An error has occurred" color="red">
          <:action>
            <%= ~t"Show more"m %>
          </:action>
          <%= @error %>
        </.collapsible_notification>
      </div>
      <.simple_form
        :let={filter_form}
        for={@filter_form}
        phx-target={@myself}
        phx-change="filter_form:validate"
        phx-submit="filter_form:submit"
        onkeydown="return event.key != 'Enter';"
        class="contents"
      >
        <div class="h-full overflow-y-auto">
          <.filter_form_component
            component={filter_form}
            resource={@meta.resource}
            collapsible_state={@collapsible_state}
            target={@myself}
          />
        </div>
        <:actions class="justify-between" modal>
          <button disabled={@filter_form.valid? == false} type="submit" class="btn btn-primary">
            <.icon
              name="hero-cog-6-tooth-solid animate-spin"
              class="hidden opacity-0 phx-submit-loading:inline-flex phx-submit-loading:opacity-100 ease-linear duration-300"
            />
            <%= mgettext("Show %{count} %{label}", count: @count, label: @label) %>
          </button>
          <button
            type="button"
            phx-click="filter_form:reset"
            phx-target={@myself}
            class="btn btn-ghost !-mx-4"
          >
            <%= ~t"Clear all"m %>
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :component, :map, required: true, doc: "Could be a FilterForm (group) or a Predicate"
  attr :resource, :atom, required: true, doc: "The resource to filter"
  attr :collapsible_state, :map, required: true, doc: "The state of the collapsible components"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  defp filter_form_component(%{component: %{source: %Predicate{field: :tax_scientific_name}}} = assigns) do
    ~H"""
    <div class="px-6">
      <.fieldset
        legend={~t"Scientific Name"m}
        text={~t"Search your records by scientifc name"m}
        legend_size="xl"
        class="border-black-white/10 border-b py-8"
      >
        <.fieldgroup>
          <.input type="hidden" field={@component[:field]} />
          <.input type="hidden" field={@component[:operator]} />
          <.field field={@component[:value]} class="w-full" phx-debounce="300" />
        </.fieldgroup>
      </.fieldset>
    </div>
    """
  end

  defp filter_form_component(%{component: %{source: %FilterForm{key: "eve_event_date_range"}}} = assigns) do
    ~H"""
    <div class="px-6">
      <.fieldset
        legend={~t"Date"m}
        text={~t"Search your records by occurrence date"m}
        legend_size="xl"
        class="border-black-white/10 border-b py-8"
      >
        <.fieldgroup class="flex flex-col gap-8 sm:flex-row">
          <.inputs_for :let={component} field={@component[:components]}>
            <.filter_form_component
              component={component}
              resource={@resource}
              collapsible_state={@collapsible_state}
              target={@target}
            />
          </.inputs_for>
        </.fieldgroup>
      </.fieldset>
    </div>
    """
  end

  defp filter_form_component(
         %{component: %{source: %Predicate{field: :eve_event_date, operator: :greater_than_or_equal}}} = assigns
       ) do
    assigns =
      assigns
      |> assign(:date_min, Cldr.Calendar.date_from_tuple({1800, 1, 1}))
      |> assign(:date_max, Cldr.Calendar.current(Date.utc_today(), :day))

    ~H"""
    <.input type="hidden" field={@component[:field]} />
    <.input type="hidden" field={@component[:operator]} />
    <.field
      type="date"
      field={@component[:value]}
      label={~t"From"}
      min={Date.to_string(@date_min)}
      max={Date.to_string(@date_max)}
      description={mgettext("From %{date}", date: format_date(@date_min))}
      phx-debounce="300"
    />
    """
  end

  defp filter_form_component(
         %{component: %{source: %Predicate{field: :eve_event_date, operator: :less_than_or_equal}}} = assigns
       ) do
    assigns =
      assigns
      |> assign(:date_min, Cldr.Calendar.date_from_tuple({1800, 1, 1}))
      |> assign(:date_max, Cldr.Calendar.current(Date.utc_today(), :day))

    ~H"""
    <.input type="hidden" field={@component[:field]} />
    <.input type="hidden" field={@component[:operator]} />
    <.field
      type="date"
      field={@component[:value]}
      label={~t"To"}
      min={Date.to_string(@date_min)}
      max={Date.to_string(@date_max)}
      description={mgettext("To %{date}", date: format_date(@date_max))}
      phx-debounce="300"
    />
    """
  end

  defp filter_form_component(%{component: %{source: %FilterForm{key: "taxonomy"}}} = assigns) do
    ~H"""
    <div class="pt-4">
      <details
        class="collapse collapse-arrow rounded-none px-6"
        open={open_collapsible?(@collapsible_state, "taxonomy")}
      >
        <summary
          class="collapse-title text-base-content text-xl/6 max-w-4xl px-0 font-bold text-inherit max-sm:line-clamp-2 after:!end-1 sm:truncate"
          phx-click="collapsible_state:toggle"
          phx-value-key="taxonomy"
          phx-target={@target}
        >
          <%= ~t"Taxonomy"m %>
        </summary>
        <div class="collapse-content space-y-6 px-0">
          <.inputs_for :let={component} field={@component[:components]}>
            <.filter_form_component
              component={component}
              resource={@resource}
              collapsible_state={@collapsible_state}
              target={@target}
            />
          </.inputs_for>
        </div>
      </details>
      <div class="px-6">
        <div class="border-black-white/10 border-b pt-4" />
      </div>
    </div>
    """
  end

  defp filter_form_component(%{component: %{source: %Predicate{field: :tax_kingdom}}} = assigns) do
    ~H"""
    <.fieldset legend={~t"Kingdom"m} legend_size="md">
      <.fieldgroup class="!mt-3">
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.field type="checkgroup" field={@component[:value]} multiple options={tax_kingdom_options()} />
      </.fieldgroup>
    </.fieldset>
    """
  end

  defp filter_form_component(%{component: %{source: %Predicate{field: :tax_phylum}}} = assigns) do
    ~H"""
    <.fieldset legend={~t"Phylum"m} legend_size="md">
      <.fieldgroup class="!mt-3">
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.field type="checkgroup" field={@component[:value]} multiple options={tax_phylum_options()} />
      </.fieldgroup>
    </.fieldset>
    """
  end

  defp filter_form_component(%{component: %{source: %FilterForm{key: "location"}}} = assigns) do
    ~H"""
    <div class="py-4">
      <details
        class="collapse collapse-arrow rounded-none px-6"
        open={open_collapsible?(@collapsible_state, "location")}
      >
        <summary
          class="collapse-title text-base-content text-xl/6 max-w-4xl px-0 font-bold text-inherit max-sm:line-clamp-2 after:!end-1 sm:truncate"
          phx-click="collapsible_state:toggle"
          phx-value-key="location"
          phx-target={@target}
        >
          <%= ~t"Location"m %>
        </summary>
        <div class="collapse-content space-y-6 px-0">
          <.inputs_for :let={component} field={@component[:components]}>
            <.filter_form_component
              component={component}
              resource={@resource}
              collapsible_state={@collapsible_state}
              target={@target}
            />
          </.inputs_for>
        </div>
      </details>
    </div>
    """
  end

  defp filter_form_component(%{component: %{source: %Predicate{field: :loc_continent}}} = assigns) do
    ~H"""
    <.fieldset legend={~t"Continent"m} legend_size="md">
      <.fieldgroup class="!mt-3">
        <.input type="hidden" field={@component[:field]} />
        <.input type="hidden" field={@component[:operator]} />
        <.input type="hidden" field={@component[:path]} />
        <.field
          type="checkgroup"
          field={@component[:value]}
          multiple
          options={loc_continent_options()}
        />
      </.fieldgroup>
    </.fieldset>
    """
  end

  defp filter_form_component(%{component: %{source: %FilterForm{}}} = assigns) do
    ~H"""
    <.inputs_for :let={component} field={@component[:components]}>
      <.filter_form_component
        component={component}
        resource={@resource}
        collapsible_state={@collapsible_state}
        target={@target}
      />
    </.inputs_for>
    """
  end

  defp filter_form_component(%{component: %{source: %Predicate{}}} = assigns) do
    ~H"""
    <.input type="hidden" field={@component[:field]} />
    <.input type="hidden" field={@component[:operator]} />
    <.input type="hidden" field={@component[:value]} />
    """
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

    socket
    |> assign(:filter_form, filter_form)
    |> assign(:error, nil)
    |> update_count(FilterForm.params_for_query(filter_form))
    |> noreply()
  end

  @impl true
  def handle_event("filter_form:reset", _, socket) do
    filter_form = init_form(socket.assigns.meta.resource)

    socket
    |> assign(:filter_form, filter_form)
    |> update_count(FilterForm.params_for_query(filter_form), true)
    |> noreply()
  end

  @impl true
  def handle_event("collapsible_state:toggle", %{"key" => key}, socket) do
    collapsible_state = socket.assigns.collapsible_state
    collapsible_state = Map.update(collapsible_state, key, false, &(!&1))

    socket
    |> assign(:collapsible_state, collapsible_state)
    |> noreply()
  end

  defp assign_form(socket) do
    %{meta: %{pagify: %{filter_form: params}, resource: resource}} = socket.assigns
    filter_form = FilterForm.new(resource, params: params, initial_form: init_form(resource))

    assign(socket, :filter_form, filter_form)
  end

  defp init_form(resource) do
    resource
    |> FilterForm.new()
    |> FilterForm.add_predicate(:tax_scientific_name, :contains, nil)
    |> FilterForm.add_group(return_id?: true, key: "eve_event_date_range")
    |> then(fn {form, date_range_group_id} ->
      form
      |> FilterForm.add_predicate(:eve_event_date, :greater_than_or_equal, nil, to: date_range_group_id)
      |> FilterForm.add_predicate(:eve_event_date, :less_than_or_equal, nil, to: date_range_group_id)
    end)
    |> FilterForm.add_group(return_id?: true, key: "taxonomy")
    |> then(fn {form, taxonomy_group_id} ->
      form
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

  defp update_count(%{assigns: %{filter_form: %{valid?: false}}} = socket, _params) do
    socket
  end

  defp update_count(socket, filter_form_params, reset \\ false) do
    %{collection_id: collection_id, meta: meta} = socket.assigns

    query = Record.query_to_by_collection(collection_id)
    count = FilterForm.count(meta, filter_form_params, reset, query)

    format_count(socket, count)
  rescue
    _ ->
      filter_form = init_form(socket.assigns.meta.resource)

      socket
      |> assign(:filter_form, filter_form)
      |> assign(:error, ~t"Something went wrong, please try again.")
  end

  defp format_count(socket, count) do
    if count > 1000 do
      count = format_number(1000)
      count = "#{count}+"
      assign(socket, :count, count)
    else
      count = format_number(count)
      assign(socket, :count, count)
    end
  end

  defp assign_collapsible_state(socket) do
    active_filter_form_fields = Pagify.active_filter_form_fields(socket.assigns.meta)
    active_taxonomy = Enum.any?(~w[tax_kingdom tax_phylum], &(&1 in active_filter_form_fields))
    active_location = Enum.any?(~w[loc_continent], &(&1 in active_filter_form_fields))

    assign(socket, :collapsible_state, %{
      "taxonomy" => active_taxonomy,
      "location" => active_location
    })
  end

  def open_collapsible?(collapsible_state, key) do
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
