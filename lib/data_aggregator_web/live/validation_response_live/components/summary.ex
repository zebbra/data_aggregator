defmodule DataAggregatorWeb.ValidationResponseLive.Components.Summary do
  @moduledoc """
  This module contains components for the validation response live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]

  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.Helpers

  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, valid?: false)}
  end

  @impl true
  def update(%{validation_response: validation_response} = assigns, socket) do
    validation_response = Ash.load!(validation_response, [:attachment])

    dataframe =
      validation_response.attachment.url
      |> Helpers.fetch_file_from_url()
      |> Helpers.extract_csv_content()
      |> Explorer.DataFrame.load_csv!()

    nil_counts = nil_counts(dataframe)

    # valid only if all nil_countss are 0
    valid? =
      Enum.all?(Map.keys(nil_counts), fn key ->
        nil_counts[key] == 0
      end)

    collection_data =
      dataframe
      |> Explorer.DataFrame.frequencies(["collectionCode", "datasetName", "institutionCode"])
      |> Explorer.DataFrame.to_rows(atom_keys: true)

    # center_data =
    #   dataframe
    #   |> Explorer.DataFrame.frequencies(["center"])
    #   |> Explorer.DataFrame.to_rows(atom_keys: true)

    socket =
      socket
      |> assign(:collection_data, collection_data)
      |> assign(:nil_counts, nil_counts)
      |> assign(:valid?, valid?)
      # |> assign(:center_data, center_data)
      |> assign(:validation_response, validation_response)

    {:ok, assign(socket, assigns)}
  end

  defp nil_counts(dataframe) do
    dataframe
    |> Explorer.DataFrame.select(["catalogNumber", "collectionCode"])
    |> Explorer.DataFrame.nil_count()
    |> Explorer.DataFrame.to_rows(atom_keys: true)
    |> List.first()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title_class="!-mr-4 w-full">
        <.stepper current={2} steps={2} />
        <.section_heading
          text={~t"Summary"m}
          description={~t"Please review the summary of your import."m}
          class="mt-4"
        >
          <:actions>
            <div class="flex items-center gap-x-2">
              <span class="text-sm max-sm:hidden">{~t"State:"m}</span>
            </div>
          </:actions>
        </.section_heading>
      </.modal_header>
      <div class="contents">
        <div class="h-full space-y-12 overflow-y-auto px-6 py-8">
          <div class="space-y-4">
            <%= if @valid? do %>
              <p class="text-sm">
                {~t"You are about to import"m}
                <span class="font-bold">
                  {mgettext(
                    "%{count} %{type}",
                    # TODO: get number
                    count: format_number(15),
                    type: type(@validation_response.type)
                  )}
                </span>
                {~t"records."m}
              </p>
              <p class="text-sm">
                {mgettext(
                  "Based on the file provided, you are importing %{type} records from:",
                  type: type(@validation_response.type)
                )}
              </p>

              <div>
                <%!-- <.table items={@center_data}>
                <:col :let={data} label={~t"Center"m}>
                  {data.center}
                </:col>
                <:col :let={data} label={~t"Count"m}>
                  {data.counts}
                </:col>
              </.table> --%>
              </div>
              <p class="text-sm">
                {mgettext(
                  "You are importing %{type} records to:",
                  type: type(@validation_response.type)
                )}
              </p>

              <div>
                <.table items={@collection_data}>
                  <:col :let={data} label={~t"Dataset"m}>
                    {data.datasetName}
                  </:col>
                  <:col :let={data} label={~t"Dataset Code"m}>
                    {data.collectionCode}
                  </:col>
                  <:col :let={data} label={~t"Institution Code"m}>
                    {data.institutionCode}
                  </:col>
                  <:col :let={data} label={~t"Count"m}>
                    {data.counts}
                  </:col>
                </.table>
              </div>
            <% else %>
              <div class="flex">
                <div class="mr-4 flex-shrink-0">
                  <.icon name="hero-exclamation-triangle-mini" class="size-6 text-warning" />
                </div>
                <p class="text-sm">
                  {~t"There are invalid rows in the provided file. Some of the required attributes are not set"m}
                </p>
              </div>
              <.table items={@nil_counts}>
                <:col :let={nil_count} label={~t"Attribute"m}>
                  {elem(nil_count, 0)}
                </:col>
                <:col :let={nil_count} label={~t"Count"m}>
                  {elem(nil_count, 1)}
                </:col>
              </.table>
            <% end %>
          </div>
        </div>
      </div>

      <.modal_footer id={@id}>
        <button
          disabled={@valid? == false}
          type="button"
          class="btn btn-primary"
          phx-click="validation_response:run"
          phx-value-id={@validation_response.id}
          phx-target={@myself}
        >
          {~t"Run validation_response"m}
        </button>
        <.link patch={~p"/validation_responses"} type="button" class="btn btn-ghost">
          {~t"Cancel"m}
        </.link>
      </.modal_footer>
    </div>
    """
  end

  @impl true
  def handle_event("validation_response:run", _params, socket) do
    actor = get_actor(socket)

    case ValidationResponse.enqueue(
           socket.assigns.validation_response,
           %{started_by_id: actor.id},
           actor: actor
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, ~t"Validation Response ingestion started in background"m)
         |> close_and_redirect()}

      {:error, error} ->
        Logger.error("Running of validation response ingestion went wrong, error: #{inspect(error)}")

        {:noreply,
         socket
         |> put_flash(:error, ~t"Something went wrong with the Validation Response ingestion"m)
         |> close_and_redirect()}
    end
  end

  defp close_and_redirect(socket) do
    socket
    |> push_event("submit:close", %{})
    |> push_navigate(to: ~p"/validation_responses")
  end

  defp type(:validated), do: ~t"validated"m
  defp type(:not_validated), do: ~t"not validated"m
end
