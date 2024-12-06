defmodule DataAggregatorWeb.CollectionLive.Record.FastTrackModal do
  @moduledoc """
  Fast track publication modal
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [filter_map: 3]

  alias AshPhoenix.Form
  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:agreed, false)
     |> assign(:creation_option, "new")
     |> assign(:dataset_key, nil)
     |> assign(:dataset_key_valid, nil)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_count() |> assign_grscicoll_data() |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mb-0 contents">
      <.simple_form
        for={@form}
        phx-change="publication:change"
        phx-submit="publication:submit"
        phx-target={@myself}
        id="publication-form"
        modal
        novalidate
      >
        <.modal_header id={@id}>
          <.stepper current={@step} steps={3} />
          <.section_heading text={modal_title(@step)} class="mt-4" />
        </.modal_header>
        <div class="h-full space-y-12 overflow-y-auto">
          <.fieldset id="publication" modal>
            {body(assigns, 1)}
            {body(assigns, 2)}
            {body(assigns, 3)}

            <:actions modal>
              {footer(assigns)}
            </:actions>
          </.fieldset>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("publication:next", _params, %{assigns: %{step: step}} = socket) do
    {:noreply, assign(socket, :step, step + 1)}
  end

  @impl true
  def handle_event("publication:back", _params, %{assigns: %{step: step}} = socket) do
    {:noreply, assign(socket, :step, step - 1)}
  end

  @impl true
  def handle_event("toggle:agree", _params, socket) do
    {:noreply, assign(socket, :agreed, !socket.assigns.agreed)}
  end

  @impl true
  def handle_event("publication:change", params, socket) do
    socket =
      socket
      |> maybe_assign_creation_option(params)
      |> maybe_assign_dataset_key(params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("publication:submit", %{"publication" => params}, socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:fast_track_query], lazy?: true, actor: actor)

    fast_track_query = filter_map(ash_pagify, collection.fast_track_query, socket.assigns.layer)

    count_query =
      Record
      |> AshPagify.query_for_filters_map(fast_track_query)
      |> Ash.Query.set_tenant(collection)

    params =
      Map.merge(params, %{
        name: "pub-#{socket.assigns.collection.name}-#{:os.system_time()}",
        channel: :fast_track,
        records_query: fast_track_query,
        collection: collection,
        rows_count: Ash.count!(count_query)
      })

    params
    |> Publication.create!(tenant: collection)
    |> Publication.enqueue(%{started_by_id: actor.id}, actor: actor)

    send(self(), {"fast_track_pub:submit", %{}})

    {:noreply, socket |> assign(:agreed, false) |> push_event("submit:close", %{})}
  end

  @impl true
  def handle_event("dataset_key:check", _params, socket) do
    # Check if the dataset key is valid

    # TODO: Implement the check
    {:noreply, assign(socket, :dataset_key_valid, true)}
  end

  defp modal_title(1), do: ~t"Publication of Records"
  defp modal_title(2), do: ~t"Target Dataset"
  defp modal_title(3), do: ~t"Publication summary"

  defp body(assigns, 1) do
    ~H"""
    <div class={unless @step == 1, do: "hidden"}>
      <div class="h-full space-y-4 overflow-y-auto p-6">
        <p class="text-sm">
          {~t"You are about to send"m}
          <span class="font-bold">
            {mgettext(
              "%{count} records from the %{layer} layer",
              count: format_number(@count),
              layer: @layer
            )}
          </span>
          {~t"to GBIF, making them publicly available. Make sure that the layer you are publishing corresponds to the filters you wish to use. Also, be aware that the records without a value for the"m}
          <span class="font-bold">{~t"kingdom "m}</span>
          {~t"attribute will not be published."m}
        </p>

        <%= if @collection.gbif_dataset_key do %>
          <div class="flex">
            <div class="mr-4 flex-shrink-0">
              <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
            </div>
            <p class="text-sm">
              {~t"This collection has already been published on"m}
              <.link
                :if={@collection.gbif_dataset_key !== nil}
                class="link link-primary link-hover"
                target="_blank"
                href={"#{gbif_base_url()}/dataset/#{@collection.gbif_dataset_key}"}
              >
                {~t"GBIF"}
                <.icon name="hero-arrow-top-right-on-square" class="size-4" />
              </.link>
              {~t". Publishing this collection will publish into the already used dataset."m}
            </p>
          </div>
        <% else %>
          <div class="flex">
            <div class="mr-4 flex-shrink-0">
              <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
            </div>
            <p class="text-sm">
              {~t"This collection has not yet been published. Please choose whether to create a new dataset on GBIF (recommended) or publish your data into an existing dataset (exports)."m}
            </p>
          </div>
          <.fieldgroup class="space-y-3">
            <.field
              type="radio"
              name="creation_option"
              id="creation_option_1"
              label={~t"Create new dataset"m}
              description={~t"A new dataset will be created on GBIF."m}
              checked={@creation_option == "new"}
              value="new"
            />
            <.field
              type="radio"
              name="creation_option"
              id="creation_option_2"
              label={~t"Use existing dataset"m}
              description={~t"Your records will be published into an existing dataset on GBIF."m}
              checked={@creation_option == "existing"}
              value="existing"
              disabled
            />
            <%= if @creation_option == "existing" do %>
              <div class="pl-10">
                <.custom_field
                  type="text"
                  name="dataset_key"
                  value={@dataset_key}
                  placeholder={~t"Dataset Key"m}
                  class="pb-6"
                >
                  <:content :let={value}>
                    <div class="inline-flex gap-x-3 sm:col-span-2">
                      <.input {value} class="w-full" />
                      <button
                        type="button"
                        class="btn btn-primary"
                        phx-click="dataset_key:check"
                        phx-target={@myself}
                      >
                        {~t"Check"m}
                      </button>
                    </div>
                    <%= unless @dataset_key_valid == nil do %>
                      <%= if @dataset_key_valid == true do %>
                        <p id={"#{@id}_success"} class="text-base/6 mt-1 sm:text-sm/6">
                          <span class="text-success">
                            {~t"Dataset {datasetName} was found"m}
                          </span>
                        </p>
                      <% else %>
                        <.errors errors={["No dataset was found"]} id={@id} class="mt-1" />
                      <% end %>
                    <% end %>
                  </:content>
                </.custom_field>
                <p class="text-sm">
                  {~t"For security reasons: Please provide your institution code and the institution code of the dataset you are going to publish into."m}
                </p>
              </div>
            <% end %>
          </.fieldgroup>
        <% end %>
      </div>
    </div>
    """
  end

  defp body(assigns, 2) do
    ~H"""
    <div class={unless @step == 2, do: "hidden"}>
      <div class="h-full overflow-y-auto overflow-x-hidden px-6 py-1">
        <.section_heading
          text={~t"Dataset"m}
          description={~t"Basic metadata regarding the dataset."m}
          size="md"
          class="pt-4"
        />

        <.list dense>
          <:item title={~t"Title"m}>
            {"#{@grscicoll_data["name"]} (#{@grscicoll_data["code"]}) of #{@grscicoll_data["institutionName"]}"}
          </:item>
          <:item title={~t"Publisher"m}>
            <.link
              target="_blank"
              rel="noopener noreferrer"
              class="text-primary"
              href="https://www.gbif.org/publisher/9661d20d-86b6-4485-8948-f3c86b022fa7"
            >
              {"SwissNatColl"}
            </.link>
          </:item>
          <:item
            :if={
              persons(@grscicoll_data, "creator") ++ persons(@grscicoll_data, "metadataprovider") !=
                []
            }
            title={~t"Authors"}
          >
            <div :for={
              person <-
                (persons(@grscicoll_data, "creator") ++ persons(@grscicoll_data, "metadataprovider"))
                |> Enum.uniq()
            }>
              {person}
            </div>
          </:item>
        </.list>

        <.section_heading
          text={~t"Institution and contact Information"m}
          description={~t"Metadata regarding the institution and contacts based on GrSciColl."m}
          size="md"
          class="pt-4"
        />
        <.list dense>
          <:item title={~t"Institution"m}>
            {@grscicoll_data["institutionName"]}
          </:item>
          <:item title={~t"Institution Code"}>
            {@grscicoll_data["code"]}
          </:item>
          <:item title={~t"Address"}>
            <div>
              <p>{@grscicoll_data["address"]["address"]}</p>
              <p>
                {@grscicoll_data["address"]["postalCode"]} {@grscicoll_data["address"]["city"]}
              </p>
              <p>{@grscicoll_data["address"]["country"]}</p>
            </div>
          </:item>
          <:item :if={persons(@grscicoll_data, "creator") != []} title={~t"Originator"}>
            <div :for={person <- persons(@grscicoll_data, "creator")}>
              {person}
            </div>
          </:item>
          <:item
            :if={persons(@grscicoll_data, "metadataprovider") != []}
            title={~t"Metadata Provider"}
          >
            <div :for={person <- persons(@grscicoll_data, "metadataprovider")}>
              {person}
            </div>
          </:item>
          <:item
            :if={persons(@grscicoll_data, "contact") != []}
            title={~t"Administrative point of contact"}
          >
            <div :for={person <- persons(@grscicoll_data, "contact")}>
              {person}
            </div>
          </:item>
        </.list>

        <.section_heading
          text={~t"Intellectual property rights"m}
          description={~t"Please choose under what license this publication and dataset is covered."m}
          size="md"
          class="pt-4"
        />
        <div class="grid grid-cols-1 pb-4">
          <.field
            type="combobox"
            field={@form[:license]}
            options={[{"CC BY", :cc_by}, {"CC0", :cc0}, {"CC BY-NC", :cc_by_nc}]}
            placeholder={~t"Select institutions"m}
            data-portal="fast_track_pub_modal"
          />
        </div>
      </div>
    </div>
    """
  end

  defp body(assigns, 3) do
    ~H"""
    <div class={unless @step == 3, do: "hidden"}>
      <div class="h-full space-y-4 overflow-y-auto p-6">
        <p class="text-sm">
          {~t"You are about to"m}
          <span class="font-bold">
            {cond do
              @collection.gbif_dataset_key -> ~t"publish into the already used dataset"m
              @creation_option == "new" -> ~t"create a new dataset"m
              @creation_option == "existing" -> ~t"use an existing dataset"m
            end}
          </span>
          {~t"and send"m}
          <span class="font-bold">
            {mgettext(
              "%{count} records",
              count: format_number(@count)
            )}
          </span>
          {~t"to GBIF"m}
        </p>
        <.list dense>
          <:item title={~t"Dataset Title"m}>
            {"#{@grscicoll_data["name"]} (#{@grscicoll_data["code"]}) of #{@grscicoll_data["institutionName"]}"}
          </:item>
        </.list>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-exclamation-triangle-mini" class="size-6 text-warning" />
          </div>
          <p class="text-sm">
            {~t"The action of publishing data is irreversible and removing records after publication is not automatically supported by the Data Aggregator and requires manual intervention on GBIF. It is therefore"m}
            <span class="text-sm font-bold">
              {~t"your responsibility"m}
            </span>
            {~t"to guarantee the quality of the data being served and to ensure that the dataset does not include sensitive information. Should you need to revise any dataset after publication, you will need to contact"m}
            <.link class="link link-primary link-hover" target="_blank" href="https://gbif.ch">
              {~t"GBIF.ch"}
              <.icon name="hero-arrow-top-right-on-square" class="size-4" />
            </.link>
            <.link href="mailto:contact@gbif.ch" class="text-primary">
              {"(contact@gbif.ch)"}
            </.link>
            {~t" for assistance."m}
          </p>
        </div>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-sm">
            {~t"The publisher of your dataset on GBIF is SwissNatColl, but your institution retains ownership of the data at all times."m}
          </p>
        </div>
        <label class="flex" phx-click="toggle:agree" phx-target={@myself}>
          <div class="mr-[1.125rem] mt-0.5 ml-0.5 flex-shrink-0">
            <input
              type="checkbox"
              id="confirm"
              name="confirm"
              checked={@agreed}
              class="checkbox checkbox-sm"
            />
          </div>
          <p class="text-sm">
            {~t"I have read and agree with the"m}
            <.link
              href="https://swissnatcoll.hp.gbif-staging.org/en/terms"
              target="_blank"
              rel="noopener noreferrer"
              class="text-primary"
            >
              {~t"terms of use"m}
            </.link>
            {~t"of the DAGI and accept full responsibility for the publication of these data."m}
          </p>
        </label>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-base-content/60 text-sm">
            {~t"The terms of use are currently under revision and may change in the coming weeks to better meet legal and regulatory requirements. In the time being, the publication of the data will be done on the GBIF test environment. The publication of the data to GBIF will become effective on the 27th of January, date on which you will be asked to revise and re-publish your dataset, by accepting the final terms of use of the DAGI."m}
          </p>
        </div>
        <p class="text-base-content/60 pt-4 text-sm">
          {~t"By clicking Publish the publication will be triggered and no further action is required. Please note that this process may take some time."m}
        </p>
      </div>
    </div>
    """
  end

  defp footer(%{step: 1} = assigns) do
    ~H"""
    <button type="button" class="btn btn-primary" phx-click="publication:next" phx-target={@myself}>
      {~t"Next"m}
    </button>
    <button class="btn btn-ghost">
      {~t"Cancel"m}
    </button>
    """
  end

  defp footer(%{step: 2} = assigns) do
    ~H"""
    <button type="button" class="btn btn-primary" phx-click="publication:next" phx-target={@myself}>
      {~t"Next"m}
    </button>
    <button type="button" class="btn btn-primary" phx-click="publication:back" phx-target={@myself}>
      {~t"Back"m}
    </button>
    """
  end

  defp footer(%{step: 3} = assigns) do
    ~H"""
    <button type="submit" class="btn btn-primary" disabled={!@agreed}>
      {~t"Publish"m}
    </button>
    <button type="button" class="btn btn-ghost" phx-click="publication:back" phx-target={@myself}>
      {~t"Back"m}
    </button>
    """
  end

  defp persons(%{"contactPersons" => persons}, type) do
    persons
    |> Enum.filter(fn person ->
      person["position"]
      |> Enum.map(&String.downcase/1)
      |> Enum.member?(type)
    end)
    |> Enum.map(&"#{&1["firstName"]} #{&1["lastName"]}")
  end

  defp assign_form(socket) do
    assign(
      socket,
      :form,
      Publication
      |> Form.for_create(:create,
        domain: DataAggregator.Records,
        as: "publication",
        actor: get_actor(socket),
        tenant: socket.assigns.collection
      )
      |> to_form()
    )
  end

  defp assign_count(socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:fast_track_query], lazy?: true, actor: actor)

    fast_track_query = filter_map(ash_pagify, collection.fast_track_query, socket.assigns.layer)

    count_query =
      Record
      |> AshPagify.query_for_filters_map(fast_track_query)
      |> Ash.Query.set_tenant(collection)

    assign(socket, :count, Ash.count!(count_query))
  end

  defp assign_grscicoll_data(socket) do
    {:ok, grscicoll_data} =
      RestAPI.get_one_collection(socket.assigns.collection.grscicoll_reference)

    assign(socket, :grscicoll_data, grscicoll_data)
  end

  defp maybe_assign_creation_option(socket, %{"creation_option" => creation_option}) do
    assign(socket, :creation_option, creation_option)
  end

  defp maybe_assign_creation_option(socket, _params), do: socket

  defp maybe_assign_dataset_key(socket, %{"dataset_key" => dataset_key}) do
    assign(socket, :dataset_key, dataset_key)
  end

  defp maybe_assign_dataset_key(socket, _params), do: socket
end
