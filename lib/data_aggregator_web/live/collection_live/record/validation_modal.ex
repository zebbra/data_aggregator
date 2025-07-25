defmodule DataAggregatorWeb.CollectionLive.Record.ValidationModal do
  @moduledoc false

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [filter_map: 3]

  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_counts()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title={~t"Validation summary"} />
      <div id={"#{@id}_inner_body"} class="h-full space-y-4 overflow-y-auto p-6">
        <p class="mb-4 text-sm">
          {mgettext(
            "You are about to send %{count} records for validation by InfoSpecies. These records will be reviewed, validated and then eventually published to GBIForg.",
            count: format_number(@count)
          )}
        </p>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-sm">
            {~t"In addition to the filters provided, we also add the restriction for all records that the"m}
            <span class="font-bold">{~t"kingdom  "m}</span>
            {~t"attribute must be set."m}
          </p>
        </div>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-sm">
            {~t"Please note that only Swiss specimen will be reviewed. All other specimen will be ignored during the validation process."m}
          </p>
        </div>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-sm">
            {~t"Please note that the validation process will involve manual work by InfoSpecies, which will review and validate each record for accuracy before publication to GBIF."m}
          </p>
        </div>
        <p class="text-sm">
          {~t"Based on the information provided, we will create exports towards the following centers:"m}
        </p>
        <.table
          opts={[container_attrs: [class: "pb-4"]]}
          id="center_and_record_counts_table"
          items={@center_and_record_counts}
        >
          <:col :let={center} label={~t"Center"}>
            {center[:name]}
          </:col>
          <:col :let={center} label={~t"Count"} class="text-right">
            {format_number(center[:count])}
          </:col>
        </.table>
        <div :if={@centered_count == 0} class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-x-circle-mini" class="size-6 text-error" />
          </div>
          <p class="text-sm">
            {~t"There are no Swiss specimen availabe. Either your specimen are outside of Switzerland or you have applied a too restrictive filter."m}
          </p>
        </div>
        <p class="text-base-content/60 mt-4 text-sm">
          {~t"By clicking"m} <span class="text-base-content italic">{~t"Validate"m}</span>
          {~t"an export will be created and automatically sent to InfoSpecies. No further action is required. Please note that this process may take some time."m}
        </p>
      </div>
      <.modal_footer id={@id}>
        <form method="dialog" class="contents">
          <button
            type="submit"
            value="confirm"
            class="btn btn-primary"
            disabled={@busy or @centered_count == 0}
          >
            {~t"Validate"m}
          </button>
          <button class="btn btn-ghost">
            {~t"Cancel"m}
          </button>
        </form>
      </.modal_footer>
    </div>
    """
  end

  defp assign_counts(socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:validation_query], lazy?: true, actor: actor)

    validation_query = filter_map(ash_pagify, collection.validation_query, socket.assigns.layer)

    count_query =
      Record
      |> AshPagify.query_for_filters_map(validation_query)
      |> Ash.Query.set_tenant(collection)

    count = Ash.count!(count_query)

    infospecies_centers = InfospeciesCenters.get_center_names()

    center_and_record_counts =
      Enum.map(infospecies_centers, fn center ->
        records_query =
          AshPagify.merge_filters(%AshPagify{filters: validation_query}, %{
            encoded_record: %{swiss_species: %{center: %{eq: center}}}
          }).filters

        center_count_query =
          Record
          |> AshPagify.query_for_filters_map(records_query)
          |> Ash.Query.set_tenant(collection)

        center_rows_count = Ash.count!(center_count_query)

        %{name: InfospeciesCenters.translate_center(center), count: center_rows_count}
      end)

    centered_count =
      Enum.reduce(center_and_record_counts, 0, fn %{count: count}, acc -> acc + count end)

    socket
    |> assign(:count, count)
    |> assign(:center_and_record_counts, center_and_record_counts)
    |> assign(:centered_count, centered_count)
  end
end
