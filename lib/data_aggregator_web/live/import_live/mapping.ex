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
  def handle_event("apply:mapping", _params, socket) do
    case Import.update_mapping(socket.assigns.import, get_static_mappings()) do
      {:ok, import} ->
        {:noreply, socket |> push_redirect(to: ~p"/imports/#{import}/confirmation")}

      {:error, _error} ->
        {:noreply, socket |> put_flash(:error, "Failed to apply mapping, check the logs.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <.header class="top-16 sticky">
        Define the mapping for your import of your collection '<%= @import.collection.name %>'
        <:actions>
          <.button
            variant="primary"
            class="rounded-md"
            aria-label={~t"Apply Mapping"m}
            phx-click="apply:mapping"
          >
            <.icon name="hero-check-circle" class="sm:-ml-0.5 sm:mr-1.5 w-5 h-5" />
            <%= ~t"Apply Mapping"m %>
          </.button>
        </:actions>
      </.header>

      <div class="justify-items-center grid">
        <ul
          role="list"
          class="dark:text-gray-400 px-7 2xl:w-4/12 xl:w-8/12 lg:w-8/12 md:w-8/12 sm:9/12 divide-slate-600 divide-dashed w-full mt-2 text-sm text-gray-500 divide-y"
        >
          <li class="gap-x-6 flex justify-between py-1 text-gray-200">
            <div class="gap-x-4 flex min-w-0">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-10">Column</p>
              </div>
            </div>
            <div class="gap-x-4 flex min-w-0">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-10">Type</p>
              </div>
            </div>
          </li>
          <%= for column <- @import.columns do %>
            <li class="gap-x-6 flex justify-between py-1">
              <div class="gap-x-4 flex min-w-0">
                <div class="flex-auto min-w-0">
                  <p class="text-sm leading-10"><%= column.name %></p>
                </div>
              </div>
              <div class="gap-x-4 flex min-w-0">
                <div class="flex-auto min-w-0">
                  <p class="text-sm leading-10"><%= column.type %></p>
                </div>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
      <.back navigate={~p"/imports"}>
        <%= ~t"Back"m %>
      </.back>
    </main>
    """
  end

  defp get_static_mappings do
    [
      %{name: "Scientific Name", mapped_to: "tax_scientific_name"},
      %{name: "Age", mapped_to: "spp_life_stage"},
      %{name: "Auteur et date ssp", mapped_to: "tax_scientific_name_authorship"},
      %{name: "Autres numéros", mapped_to: "occ_associated_occurrences"},
      %{name: "Collecteur", mapped_to: "occ_recorded_by"},
      %{name: "DAYCOLLECTED", mapped_to: "eve_day"},
      %{name: "ENDOFPERIODDAY", mapped_to: "eve_end_of_period_day"},
      %{name: "ENDOFPERIODMONTH", mapped_to: "eve_end_of_period_month"},
      %{name: "ENDOFPERIODYEAR", mapped_to: "eve_end_of_period_year"},
      %{name: "Espèce", mapped_to: "tax_specific_epithet"},
      %{name: "Famille", mapped_to: "tax_family"},
      %{name: "Genre", mapped_to: "tax_genus"},
      %{name: "LatitudeDecimale", mapped_to: "loc_decimal_latitude"},
      %{name: "Localité", mapped_to: "loc_verbatim_locality"},
      %{name: "LongitudeDecimale", mapped_to: "loc_decimal_longitude"},
      %{name: "MONTHCOLLECTED", mapped_to: "eve_month"},
      %{name: "Numéro scientifique GBIF", mapped_to: "mte_material_entity_id"},
      %{name: "Ordre", mapped_to: "tax_order"},
      %{name: "Parties", mapped_to: "mts_material_sample_type"},
      %{name: "Pays", mapped_to: "loc_country"},
      %{name: "PrecisionGEO", mapped_to: "loc_georeference_remarks"},
      %{name: "Province", mapped_to: "loc_state_province"},
      %{name: "Remarques", mapped_to: "occ_occurrence_remarks"},
      %{name: "Sexe", mapped_to: "occ_sex"},
      %{name: "Sous espèce", mapped_to: "tax_infraspecific_epithet"},
      %{name: "Station", mapped_to: "loc_locality"},
      %{name: "YEARCOLLECTED", mapped_to: "eve_year"}
    ]
  end
end
