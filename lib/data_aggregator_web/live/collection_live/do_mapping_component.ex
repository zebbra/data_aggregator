defmodule DataAggregatorWeb.CollectionLive.DoMappingComponent do
  use DataAggregatorWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> load_default_mapping()
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form_header icon={@icon} title={@title} />
      <.simple_form
        for={@form}
        id="do_mapping-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="apply_mapping"
      >
        <ul role="list" class="dark:text-gray-400 mt-2 text-sm text-gray-500">
          <li class="gap-x-6 flex justify-between py-1 text-gray-200">
            <div class="gap-x-4 flex min-w-0">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-6">Platform</p>
              </div>
            </div>
            <div class="gap-x-4 flex min-w-0">
              <div class="flex-auto min-w-0">
                <p class="text-sm font-bold leading-6">Your File</p>
              </div>
            </div>
          </li>
          <%= for dwc_attribute <- @basic_default_attributes do %>
            <li class="gap-x-6 flex justify-between py-1">
              <div class="gap-x-4 flex min-w-0">
                <div class="flex-auto min-w-0">
                  <p class="text-sm leading-6"><%= dwc_attribute.label %></p>
                </div>
              </div>
              <div class="gap-x-4 flex min-w-0">
                <div class="flex-auto min-w-0">
                  <p class="text-sm leading-6"><%= dwc_attribute.mapping %></p>
                </div>
              </div>
            </li>
          <% end %>
        </ul>

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            phx-disable-with={~t"Applying your Mapping..."m}
          >
            <%= ~t"Apply Mapping"m %>
          </.button>
          <.button
            variant="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
            phx-click={JS.exec("data-cancel", to: "#do-mapping-modal")}
            phx-disable-with
          >
            <%= ~t"Cancel"m %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :icon, :string, default: nil
  attr :title, :string, required: true

  defp form_header(assigns) do
    ~H"""
    <div class="sm:flex sm:items-start">
      <div
        :if={@icon}
        class="sm:mx-0 sm:h-10 sm:w-10 flex items-center justify-center flex-shrink-0 w-12 h-12 mx-auto bg-indigo-100 rounded-full"
      >
        <.icon name={@icon} class="w-6 h-6 text-indigo-600" />
      </div>
      <div class={["mt-3 text-center sm:mt-0 sm:text-left", @icon && "sm:ml-4"]}>
        <.dialog_title
          id="do-mapping-modal__title"
          class="dark:text-white text-base leading-6 text-gray-900"
        >
          <%= @title %>
        </.dialog_title>
        <.dialog_description
          id="do-mapping-modal__description"
          class="dark:text-gray-400 mt-2 text-sm text-gray-500"
        >
          <%= ~t"Map the columns of your file to our data fields"m %>
        </.dialog_description>
      </div>
    </div>
    """
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new}) do
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("apply_mapping", _params, socket) do
    notify_parent({:mapped, socket.assigns.import_file})

    {:noreply,
     socket
     |> push_patch(to: socket.assigns.patch)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp load_default_mapping(socket) do
    socket
    |> assign(:basic_default_attributes, [
      %{label: "material_entity_id", mapping: "Numéro scientifique GBIF"},
      %{label: "order", mapping: "Ordre"},
      %{label: "family", mapping: "Famille"},
      %{label: "genus", mapping: "Genre"},
      %{label: "specific_epithet", mapping: "Espèce"},
      %{
        label: "scientific_name_authorship",
        mapping: "Auteur et date sp."
      },
      %{label: "infraspecific_epithet", mapping: "Sous espèce"},
      %{
        label: "scientific_name_authorship",
        mapping: "Auteur et date ssp"
      },
      %{label: "sex", mapping: "Sexe"},
      %{label: "life_stage", mapping: "Age"},
      %{label: "material_sample_type", mapping: "Parties"},
      %{label: "associated_occurrences", mapping: "Autres numéros"},
      %{label: "country", mapping: "Pays"},
      %{label: "state_province", mapping: "Province"},
      %{label: "verbatim_locality", mapping: "Localité"},
      %{label: "locality", mapping: "Station"},
      %{label: "decimal_longitude", mapping: "LongitudeDecimale"},
      %{label: "decimal_latitude", mapping: "LatitudeDecimale"},
      %{label: "georeference_remarks", mapping: "PrecisionGEO"},
      %{label: "occurrence_remarks", mapping: "Remarques"},
      %{label: "day", mapping: "DAYCOLLECTED"},
      %{label: "month", mapping: "MONTHCOLLECTED"},
      %{label: "year", mapping: "YEARCOLLECTED"},
      %{label: "end_of_period_day", mapping: "ENDOFPERIODDAY"},
      %{label: "end_of_period_month", mapping: "ENDOFPERIODMONTH"},
      %{label: "end_of_period_year", mapping: "ENDOFPERIODYEAR"},
      %{label: "recorded_by", mapping: "Collecteur"}
    ])
  end
end
