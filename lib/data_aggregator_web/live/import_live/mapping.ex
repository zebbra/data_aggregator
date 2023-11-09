defmodule DataAggregatorWeb.ImportLive.Mapping do
  use DataAggregatorWeb, :live_view

  alias DataAggregator.Platform.Import

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    import = DataAggregator.Platform.load!(Import.get_by_id!(id), collection: [:id, :name])

    socket =
      socket
      |> assign(:import, import)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, :mappings, _params) do
    socket
    |> assign(:page_title, ~t"Configure Mapping for Import"m)
  end

  @impl true
  def handle_event("backto:import", _params, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/imports/#{socket.assigns.import}")}
  end

  @impl true
  def handle_event("apply:mapping", _params, socket) do
    case Import.update_mapping(socket.assigns.import, get_static_mappings()) do
      {:ok, import} ->
        {:noreply, socket |> push_navigate(to: ~p"/imports/#{import}/confirmation")}

      {:error, _error} ->
        {:noreply, socket |> put_flash(:error, "Failed to apply mapping, check the logs.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <.header class="top-16 sticky">
        Define the mapping for the import of your collection '<%= @import.collection.name %>'
        <:actions>
          <.button
            variant="nav"
            class="rounded-md"
            aria-label={~t"Back to Import"m}
            phx-click="backto:import"
          >
            <.icon name="hero-arrow-left" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <%= ~t"Back to Import"m %>
          </.button>
          <.button
            variant="primary"
            class="rounded-md"
            aria-label={~t"Apply Mapping"m}
            phx-click="apply:mapping"
          >
            <.icon name="hero-check" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <%= ~t"Apply Mapping"m %>
          </.button>
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <ul
          role="list"
          class="dark:text-gray-400 px-7 2xl:w-6/12 xl:w-/12 lg:w-9/12 md:w-8/12 sm:9/12 divide-slate-600 divide-dashed w-full mt-2 text-sm text-gray-700 divide-y"
        >
          <li class="gap-x-6 dark:text-gray-200 flex justify-between py-1">
            <div class="gap-x-4 flex justify-start w-1/3">
              <p class="text-sm font-bold leading-10">Column</p>
            </div>
            <div class="gap-x-4 flex w-1/3 text-center">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-10">required</p>
              </div>
            </div>
            <div class="gap-x-4 flex justify-end w-1/3">
              <p class="text-sm font-bold leading-10">Mapped To</p>
            </div>
          </li>
          <%= for column <- @import.columns do %>
            <li class="gap-x-6 flex justify-between py-1">
              <div class="gap-x-4 flex justify-start w-1/3">
                <p class="text-sm leading-10"><%= column.name %></p>
              </div>
              <div class="gap-x-4 flex items-center justify-center w-1/3 text-center">
                <input
                  disabled
                  checked={get_required_from_static_mappings(column.name)}
                  type="checkbox"
                  class=" w-4 h-4 text-indigo-600 rounded"
                />
              </div>
              <div class="gap-x-4 flex justify-end w-1/3">
                <p class="text-sm leading-10">
                  <%= get_mapping_from_static_mappings(column.name) %>
                </p>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
      <.back navigate={~p"/imports/#{@import}"}>
        <%= ~t"Back"m %>
      </.back>
    </main>
    """
  end

  defp get_mapping_from_static_mappings(name) do
    Enum.find(get_static_mappings(), fn mapping -> mapping.name == name end)
    |> Map.get(:mapped_to)
  end

  defp get_required_from_static_mappings(name) do
    Enum.find(get_static_mappings(), fn mapping -> mapping.name == name end)
    |> Map.get(:required)
  end

  defp get_static_mappings do
    [
      %{required: true, name: "Scientific Name", mapped_to: "tax_scientific_name"},
      %{required: true, name: "Age", mapped_to: "spp_life_stage"},
      %{required: true, name: "Auteur et date ssp", mapped_to: "tax_scientific_name_authorship"},
      %{required: true, name: "Autres numéros", mapped_to: "occ_associated_occurrences"},
      %{required: false, name: "Collecteur", mapped_to: "occ_recorded_by"},
      %{required: false, name: "DAYCOLLECTED", mapped_to: "eve_day"},
      %{required: false, name: "ENDOFPERIODDAY", mapped_to: "eve_end_of_period_day"},
      %{required: false, name: "ENDOFPERIODMONTH", mapped_to: "eve_end_of_period_month"},
      %{required: false, name: "ENDOFPERIODYEAR", mapped_to: "eve_end_of_period_year"},
      %{required: false, name: "Espèce", mapped_to: "tax_specific_epithet"},
      %{required: false, name: "Famille", mapped_to: "tax_family"},
      %{required: false, name: "Genre", mapped_to: "tax_genus"},
      %{required: false, name: "LatitudeDecimale", mapped_to: "loc_decimal_latitude"},
      %{required: false, name: "Localité", mapped_to: "loc_verbatim_locality"},
      %{required: false, name: "LongitudeDecimale", mapped_to: "loc_decimal_longitude"},
      %{required: false, name: "MONTHCOLLECTED", mapped_to: "eve_month"},
      %{required: false, name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"},
      %{required: false, name: "Ordre", mapped_to: "tax_order"},
      %{required: false, name: "Parties", mapped_to: "mts_material_sample_type"},
      %{required: false, name: "Pays", mapped_to: "loc_country"},
      %{required: false, name: "PrecisionGEO", mapped_to: "loc_georeference_remarks"},
      %{required: false, name: "Province", mapped_to: "loc_state_province"},
      %{required: false, name: "Remarques", mapped_to: "occ_occurrence_remarks"},
      %{required: false, name: "Sexe", mapped_to: "occ_sex"},
      %{required: false, name: "Sous espèce", mapped_to: "tax_infraspecific_epithet"},
      %{required: false, name: "Station", mapped_to: "loc_locality"},
      %{required: false, name: "YEARCOLLECTED", mapped_to: "eve_year"}
    ]
  end
end
