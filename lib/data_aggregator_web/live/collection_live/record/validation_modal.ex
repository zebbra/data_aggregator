defmodule DataAggregatorWeb.CollectionLive.Record.ValidationModal do
  @moduledoc false

  use DataAggregatorWeb, :live_component

  alias DataAggregator.Records.Record
  alias DataAggregator.Records.ValidationRequest
  alias DataAggregator.Taxonomy.Catalogs.InfospeciesCenters
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    first_update? = not Map.has_key?(socket.assigns, :counts)

    socket = assign(socket, assigns)

    socket =
      if first_update? do
        socket
        |> assign(:counts, AsyncResult.loading())
        |> start_async_counts()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title={~t"Validation summary"} />
      <div id={"#{@id}_inner_body"} class="h-full space-y-4 overflow-y-auto p-6">
        <.async_data :let={counts} async_result={@counts}>
          <:loading>
            <div class="space-y-4">
              <.skeleton class="h-4 w-3/4" />
              <.skeleton class="h-4 w-full" />
              <.skeleton class="h-4 w-5/6" />
              <.skeleton class="h-32 w-full" />
              <.skeleton class="h-4 w-full" />
              <.skeleton class="h-4 w-4/5" />
            </div>
          </:loading>
          <:failed>
            <div class="flex">
              <div class="mr-4 shrink-0">
                <.icon name="hero-x-circle-mini" class="size-6 text-error" />
              </div>
              <p class="text-sm">
                {~t"Failed to load the validation summary. Please close the modal and try again."m}
              </p>
            </div>
          </:failed>

          <p class="mb-4 text-sm">
            {mgettext(
              "You are about to send %{count} records for validation by InfoSpecies. These records will be reviewed and validated individually.",
              count: format_number(counts.total)
            )}
          </p>
          <div class="flex">
            <div class="mr-4 shrink-0">
              <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
            </div>
            <p class="text-sm">
              {~t"Please note that only Swiss specimens will be processed. All other specimens will be ignored. Records must have both"m}
              <span class="font-bold">{~t"kingdom and taxonID"m}</span>
              {~t"attributes set."m}
            </p>
          </div>

          <p class="text-sm">
            {~t"Based on the information provided, we will create exports towards the following centers:"m}
          </p>
          <.table
            opts={[container_attrs: [class: "pb-4"]]}
            id="center_and_record_counts_table"
            items={counts.center_and_record_counts}
          >
            <:col :let={center} label={~t"Center"}>
              {center[:name]}
            </:col>
            <:col :let={center} label={~t"Count"} class="text-right">
              {format_number(center[:count])}
            </:col>
          </.table>
          <div :if={counts.centered_count == 0} class="flex">
            <div class="mr-4 shrink-0">
              <.icon name="hero-x-circle-mini" class="size-6 text-error" />
            </div>
            <p class="text-sm">
              {~t"There are no Swiss specimen availabe. Either your specimen are outside of Switzerland or you have applied a too restrictive filter."m}
            </p>
          </div>

          <div class="flex">
            <div class="mr-4 shrink-0">
              <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
            </div>
            <p class="text-sm">
              {~t"Records that have not changed since the last validation request will be ignored and will not be sent for validation."m}
            </p>
          </div>
          <div class="flex">
            <div class="mr-4 shrink-0">
              <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
            </div>
            <p class="text-sm">
              {~t"Each record will be manually reviewed and validated by the staff at each InfoSpecies center. Their feedback on the records will be available on DAGI at the end of the process."m}
            </p>
          </div>
          <p class="text-base-content/60 mt-4 text-sm">
            {~t"By clicking on"m}
            <span class="text-base-content italic">{~t"Validate"m}</span>{~t", the records will be processed. Export files will be created and automatically sent to the specific Swiss data centers. No further action is required. Please note that this process may take some time."m}
          </p>
        </.async_data>
      </div>
      <.modal_footer id={@id}>
        <form method="dialog" class="contents">
          <button
            type="submit"
            value="confirm"
            class="btn btn-primary"
            disabled={validate_disabled?(@busy, @counts)}
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

  defp validate_disabled?(busy, counts) do
    busy or not counts.ok? or counts.result.centered_count == 0
  end

  defp start_async_counts(socket) do
    collection = socket.assigns.collection
    actor = get_actor(socket)

    assign_async(socket, :counts, fn -> load_counts(collection, actor) end)
  end

  defp load_counts(collection, actor) do
    collection = Ash.load!(collection, [:validation_query], lazy?: true, actor: actor)
    validation_query = collection.validation_query
    centers = InfospeciesCenters.get_center_names()

    [total | center_counts] =
      [fn -> count_total(collection, validation_query) end]
      |> Enum.concat(Enum.map(centers, &fn -> count_for_center(collection, validation_query, &1) end))
      |> Task.async_stream(& &1.(), ordered: true, timeout: to_timeout(second: 30))
      |> Enum.map(fn {:ok, result} -> result end)

    center_and_record_counts =
      centers
      |> Enum.zip(center_counts)
      |> Enum.map(fn {center, count} ->
        %{name: InfospeciesCenters.translate_center(center), count: count}
      end)

    centered_count = Enum.sum(center_counts)

    {:ok,
     %{
       counts: %{
         total: total,
         center_and_record_counts: center_and_record_counts,
         centered_count: centered_count
       }
     }}
  end

  defp count_total(collection, validation_query) do
    Record
    |> Ash.Query.filter_input(validation_query)
    |> Ash.Query.set_tenant(collection)
    |> Ash.count!()
  end

  defp count_for_center(collection, validation_query, center) do
    records_query =
      AshPagify.merge_filters(
        %AshPagify{filters: validation_query},
        ValidationRequest.Helpers.center_specific_filter(center)
      ).filters

    Record
    |> AshPagify.query_for_filters_map(records_query)
    |> Ash.Query.set_tenant(collection)
    |> Ash.count!()
  end
end
