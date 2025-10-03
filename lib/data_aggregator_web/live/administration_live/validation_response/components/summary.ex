defmodule DataAggregatorWeb.AdministrationLive.ValidationResponse.Components.Summary do
  @moduledoc """
  This module contains components for the validation response live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]

  alias DataAggregator.Records.DataFrame
  alias DataAggregator.Records.ValidationResponse

  require Logger

  @impl true
  def mount(socket) do
    {:ok, assign(socket, valid?: false)}
  end

  @impl true
  def update(%{validation_response: validation_response} = assigns, socket) do
    validation_response = Ash.load!(validation_response, attachment: :cached_file)

    %{cached_file: cached_file} = validation_response.attachment

    {:ok, dataframe} = DataFrame.from_file(cached_file)

    mandatory_attributes_nil_counts =
      dataframe
      |> mandatory_attributes_nil_counts()
      |> maybe_add_annotation_nil_count(validation_response.type, dataframe)
      |> Map.filter(fn {_k, v} -> v > 0 end)

    # valid only if all mandatory_attributes_nil_counts are 0
    valid? =
      Enum.all?(Map.keys(mandatory_attributes_nil_counts), fn key ->
        mandatory_attributes_nil_counts[key] == 0
      end)

    collection_attributes =
      dataframe
      |> Explorer.DataFrame.names()
      |> Enum.filter(&(&1 in ["collectionCode", "datasetName", "institutionCode"]))

    collection_data =
      dataframe
      |> Explorer.DataFrame.frequencies(collection_attributes)
      |> Explorer.DataFrame.to_rows(atom_keys: true)

    center_data =
      if Enum.member?(Explorer.DataFrame.names(dataframe), "center") do
        dataframe
        |> Explorer.DataFrame.frequencies(["center"])
        |> Explorer.DataFrame.to_rows(atom_keys: true)
      end

    socket =
      socket
      |> assign(:collection_data, collection_data)
      |> assign(:center_data, center_data)
      |> assign(:mandatory_attributes_nil_counts, mandatory_attributes_nil_counts)
      |> assign(:valid?, valid?)
      |> assign(:validation_response, validation_response)

    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title_class="!-mr-4 w-full">
        <.stepper current={2} steps={2} />
        <.section_heading text={~t"Summary"m} class="mt-4" />
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
                    count: format_number(@validation_response.rows_count),
                    type: type(@validation_response.type)
                  )}
                </span>
                {~t"records."m}
              </p>
              <%= if @center_data do %>
                <p class="text-sm">
                  {mgettext(
                    "Based on the file provided, you are importing %{type} records from:",
                    type: type(@validation_response.type)
                  )}
                </p>

                <div>
                  <.table items={@center_data}>
                    <:col :let={data} label={~t"Center"m}>
                      {data.center}
                    </:col>
                    <:col :let={data} label={~t"Count"m}>
                      {data.counts}
                    </:col>
                  </.table>
                </div>
              <% end %>
              <p class="text-sm">
                {mgettext(
                  "You are importing %{type} records to:",
                  type: type(@validation_response.type)
                )}
              </p>

              <div>
                <.table items={@collection_data}>
                  <:col :let={data} label={~t"Dataset"m}>
                    {format_collection_data(Map.get(data, :datasetName))}
                  </:col>
                  <:col :let={data} label={~t"Dataset Code"m}>
                    {format_collection_data(Map.get(data, :collectionCode))}
                  </:col>
                  <:col :let={data} label={~t"Institution Code"m}>
                    {format_collection_data(Map.get(data, :institutionCode))}
                  </:col>
                  <:col :let={data} label={~t"Count"m}>
                    {Map.get(data, :counts)}
                  </:col>
                </.table>
              </div>
            <% else %>
              <div class="flex">
                <div class="mr-4 flex-shrink-0">
                  <.icon name="hero-x-circle-mini" class="size-6 text-error" />
                </div>
                <p class="text-sm">
                  {mgettext(
                    "The import file contains invalid rows with missing attributes. The following attributes are required for all rows: %{missing_attributes}.",
                    missing_attributes: missing_attributes(@mandatory_attributes_nil_counts)
                  )}
                </p>
              </div>
              <.table items={@mandatory_attributes_nil_counts}>
                <:col :let={nil_count} label={~t"Missing attribute"m}>
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
          {~t"Import"m}
        </button>
        <.link onclick="validation_response_modal.close()" type="button" class="btn btn-ghost">
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

  defp maybe_add_annotation_nil_count(mandatory_attributes_nil_counts, :validated, _dataframe),
    do: mandatory_attributes_nil_counts

  defp maybe_add_annotation_nil_count(mandatory_attributes_nil_counts, :not_validated, dataframe) do
    if dataframe |> Explorer.DataFrame.names() |> Enum.member?("annotation") do
      Map.merge(
        mandatory_attributes_nil_counts,
        dataframe
        |> Explorer.DataFrame.select(["annotation"])
        |> Explorer.DataFrame.nil_count()
        |> Explorer.DataFrame.to_rows(atom_keys: true)
        |> List.first()
      )
    else
      Map.put(mandatory_attributes_nil_counts, :annotation, Explorer.DataFrame.n_rows(dataframe))
    end
  end

  defp mandatory_attributes_nil_counts(dataframe) do
    dataframe
    |> Explorer.DataFrame.select(["catalogNumber", "collectionCode"])
    |> Explorer.DataFrame.nil_count()
    |> Explorer.DataFrame.to_rows(atom_keys: true)
    |> List.first()
  end

  defp missing_attributes(mandatory_attributes_nil_counts) do
    mandatory_attributes_nil_counts |> Map.keys() |> Enum.join(", ")
  end

  defp close_and_redirect(socket) do
    socket
    |> push_event("submit:close", %{})
    |> push_navigate(to: ~p"/administration/validation_responses")
  end

  defp format_collection_data(nil), do: "N/A"
  defp format_collection_data(value), do: value

  defp type(:validated), do: ~t"validated"m
  defp type(:not_validated), do: ~t"not validated"m
end
