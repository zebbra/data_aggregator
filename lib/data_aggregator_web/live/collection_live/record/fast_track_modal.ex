defmodule DataAggregatorWeb.CollectionLive.Record.FastTrackModal do
  @moduledoc """
  Fast track publication modal
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]

  import DataAggregatorWeb.CollectionLive.Record.Helpers,
    only: [
      filter_map: 3,
      checked_fast_track_query: 2,
      count_from_query: 2
    ]

  import DataAggregatorWeb.Components.FieldGroup, only: [radio_group: 1]

  alias AshPhoenix.Form
  alias DataAggregator.Gbif.RestAPI
  alias DataAggregator.Records.Publication

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:step, 1)
     |> assign(:agreed, false)
     |> assign(:creation_option, "new")
     |> assign(:dataset, nil)
     |> assign(:target_dataset_name, nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_counts()
      |> assign_grscicoll_data()
      |> assign_form()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id}>
        <.stepper current={@step} steps={3} />
        <.section_heading text={modal_title(@step)} class="mt-4" />
      </.modal_header>

      <.simple_form
        for={@form}
        id="publication-form"
        class="contents"
        phx-target={@myself}
        phx-change="publication:validate"
        phx-submit="publication:submit"
        onkeydown="return event.key != 'Enter';"
        novalidate
      >
        <div class="h-full space-y-12 overflow-y-auto px-6 py-8">
          <.fieldset>
            {body(assigns, 1)}
            {body(assigns, 2)}
            {body(assigns, 3)}
          </.fieldset>
        </div>
        <:actions modal>
          {footer(assigns)}
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("publication:next", _params, socket) do
    socket
    |> update(:step, &(&1 + 1))
    |> noreply()
  end

  @impl true
  def handle_event("publication:back", _params, socket) do
    socket
    |> update(:step, &(&1 - 1))
    |> noreply()
  end

  @impl true
  def handle_event("toggle:agree", _params, socket) do
    socket
    |> update(:agreed, &(!&1))
    |> noreply()
  end

  @impl true
  def handle_event("publication:validate", %{"publication" => params, "_target" => target}, socket) do
    socket =
      if target == ["publication", "existing_dataset_key"] do
        socket |> assign(:dataset, nil) |> assign(:target_dataset_name, nil)
      else
        socket
      end

    form = socket.assigns.form
    form = Form.validate(form, params)

    socket
    |> assign(:form, form)
    |> noreply()
  end

  @impl true
  def handle_event("publication:submit", %{"publication" => params}, socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:fast_track_query], lazy?: true, actor: actor)

    fast_track_query = filter_map(ash_pagify, collection.fast_track_query, socket.assigns.layer)

    # filter for records that pass the fast track check (country is set, or no coordinates are set)
    checked_fast_track_query = checked_fast_track_query(fast_track_query, socket.assigns.layer)
    checked_fast_track_count = count_from_query(checked_fast_track_query, collection)

    params =
      Map.merge(params, %{
        name: "pub-#{socket.assigns.collection.name}-#{:os.system_time()}",
        channel: :fast_track,
        records_query: checked_fast_track_query,
        collection: collection,
        rows_count: checked_fast_track_count
      })

    socket = update(socket, :agreed, &(!&1))

    case params
         |> Publication.create!(tenant: collection)
         |> Publication.enqueue(%{started_by_id: actor.id}, actor: actor) do
      {:error, _} ->
        {:noreply, put_flash(socket, :error, ~t"A publication for this collection is already in process"m)}

      {:ok, _} ->
        socket
        |> put_flash(:info, ~t"Publication started in background"m)
        |> push_navigate(to: build_path(~p"/collections/#{socket.assigns.collection}/records", socket.assigns.meta))
        |> noreply()
    end
  end

  @impl true
  def handle_event("non_form_data:change", %{"target_dataset_name" => target_dataset_name}, socket) do
    {:noreply, assign(socket, :target_dataset_name, target_dataset_name)}
  end

  @impl true
  def handle_event("non_form_data:change", %{"creation_option" => creation_option}, socket) do
    {:noreply, assign(socket, :creation_option, creation_option)}
  end

  @impl true
  def handle_event("existing_dataset_key:check", _params, socket) do
    existing_dataset_key = socket.assigns.form.params["existing_dataset_key"]
    # Check if the dataset key is valid
    socket
    |> assign_async(:dataset, fn ->
      case RestAPI.get_grscicoll_entity(
             existing_dataset_key,
             :dataset
           ) do
        {:ok, dataset} ->
          {:ok, %{dataset: dataset}}

        {:error, _} ->
          {:ok, %{dataset: nil}}
      end
    end)
    |> noreply()
  end

  defp modal_title(1), do: ~t"Publication of Records"
  defp modal_title(2), do: ~t"Target Dataset"
  defp modal_title(3), do: ~t"Publication summary"

  defp body(assigns, 1) do
    ~H"""
    <div class={unless @step == 1, do: "hidden"}>
      <div class="space-y-4">
        <p class="text-sm">
          {~t"You are about to send"m}
          <span class="font-bold">
            {mgettext(
              "%{count} records from the %{layer} layer",
              count: format_number(@checked_fast_track_count),
              layer: @layer
            )}
          </span>
          {~t"to GBIF, making them publicly available. Make sure that the layer you are publishing corresponds to the filters you wish to use. Also, be aware that the records without a value for the"m}
          <span class="font-bold">{~t"kingdom "m}</span>
          {~t"attribute will not be published."m}
        </p>

        <div :if={@total_count - @checked_fast_track_count > 0} class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-exclamation-triangle-mini" class="size-6 text-warning" />
          </div>
          <p class="text-sm">
            {~t"There are"m}
            <span class="text-sm font-bold">
              {mgettext(
                "%{count} records",
                count: format_number(@total_count - @checked_fast_track_count)
              )}
            </span>
            {~t"that will not be published, because they did not pass the fast track check, and might contain sensitive information."m}
            {~t"Please run the encoding step, and run the publication on another layer than the 'import layer' to prevent this."m}
          </p>
        </div>

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
              phx-change="non_form_data:change"
              checked={@creation_option == "new"}
              value="new"
            />
            <.field
              type="radio"
              name="creation_option"
              id="creation_option_2"
              label={~t"Use existing dataset"m}
              description={~t"Your records will be published into an existing dataset on GBIF."m}
              phx-change="non_form_data:change"
              checked={@creation_option == "existing"}
              value="existing"
            />
            <%= if @creation_option == "existing" do %>
              <div class="pl-10">
                <.custom_field
                  field={@form[:existing_dataset_key]}
                  type="text"
                  placeholder={~t"Dataset Key"m}
                  class="pb-6"
                >
                  <:content :let={value}>
                    <div class="inline-flex gap-x-3 sm:col-span-2">
                      <.input {value} class="w-full" />
                      <button
                        type="button"
                        class="btn btn-primary"
                        phx-click="existing_dataset_key:check"
                        phx-keydown="existing_dataset_key:check"
                        phx-key="Enter"
                        phx-target={@myself}
                        disabled={
                          (@dataset != nil and @dataset.loading != nil) or
                            blank?(@form.params["existing_dataset_key"])
                        }
                      >
                        <%= if @dataset != nil and @dataset.loading do %>
                          {~t"Checking..."}
                        <% else %>
                          {~t"Check"m}
                        <% end %>
                      </button>
                    </div>
                    <%= unless @dataset == nil or @dataset.loading do %>
                      <%= if @dataset.result != nil do %>
                        <p id={"#{@id}_success"} class="text-base/6 mt-1 sm:text-sm/6">
                          <span class="text-success">
                            {mgettext("Dataset \"%{dataset_title}\" was found",
                              dataset_title: @dataset.result["title"]
                            )}
                          </span>
                        </p>
                      <% else %>
                        <.errors errors={["No dataset was found"]} id={@id} class="mt-1" />
                      <% end %>
                    <% end %>
                  </:content>
                </.custom_field>
                <%= if @dataset != nil and @dataset.result != nil do %>
                  <p class="pb-3 text-sm">
                    {~t"For security reasons: Please type in the name of the target dataset you are going to publish into."m}
                  </p>
                  <.field
                    value={@target_dataset_name}
                    name="target_dataset_name"
                    placeholder={~t"Name of target dataset"m}
                    phx-change="non_form_data:change"
                    class={
                      if @target_dataset_name == @dataset.result["title"] do
                        "[&_span]:text-success"
                      else
                        "[&_span]:text-error"
                      end
                    }
                    icon_end={
                      if @target_dataset_name == @dataset.result["title"] do
                        "hero-check"
                      else
                        "hero-x-mark"
                      end
                    }
                  />
                <% end %>
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
      <.section_heading
        text={~t"Dataset"m}
        description={~t"Basic metadata regarding the dataset."m}
        size="md"
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
        <:item :if={persons(@grscicoll_data, "metadataprovider") != []} title={~t"Metadata Provider"}>
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

      <.section_heading text={~t"Intellectual property rights"m} size="md" class="pt-4 pb-1" />
      <.radio_group
        field={@form[:license]}
        options={[{"CC BY", :cc_by}, {"CC0", :cc0}, {"CC BY-NC", :cc_by_nc}]}
        as_atoms
        description={~t"Please choose under what license this publication and dataset is covered."m}
      />
    </div>
    """
  end

  defp body(assigns, 3) do
    ~H"""
    <div class={unless @step == 3, do: "hidden"}>
      <div class="space-y-4">
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
              "%{checked_fast_track_count} records",
              checked_fast_track_count: format_number(@checked_fast_track_count)
            )}
          </span>
          {~t"to GBIF"m}
        </p>
        <.list dense>
          <:item title={~t"Dataset Title"m}>
            <%= if @creation_option == "new" do %>
              {"#{@grscicoll_data["name"]} (#{@grscicoll_data["code"]}) of #{@grscicoll_data["institutionName"]}"}
            <% else %>
              <%= if @dataset != nil do %>
                {"#{@dataset.result["title"]}"}
              <% else %>
                {~t"loading..."m}
              <% end %>
            <% end %>
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
    <button
      disabled={dataset_validation_valid?(assigns) == false}
      type="button"
      class="btn btn-primary"
      phx-click="publication:next"
      phx-target={@myself}
    >
      {~t"Next"m}
    </button>
    <button type="button" class="btn btn-ghost" onclick="fast_track_pub_modal.close()">
      {~t"Cancel"m}
    </button>
    """
  end

  defp footer(%{step: 2} = assigns) do
    ~H"""
    <button type="button" class="btn btn-primary" phx-click="publication:next" phx-target={@myself}>
      {~t"Next"m}
    </button>
    <button type="button" class="btn btn-ghost" phx-click="publication:back" phx-target={@myself}>
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

  defp dataset_validation_valid?(assigns) do
    assigns.creation_option == "new" or
      (assigns.dataset != nil and assigns.dataset.result != nil and
         assigns.target_dataset_name == assigns.dataset.result["title"])
  end

  defp assign_counts(socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:fast_track_query], lazy?: true, actor: actor)

    fast_track_query =
      filter_map(ash_pagify, collection.fast_track_query, socket.assigns.layer)

    total_count = count_from_query(fast_track_query, collection)

    checked_fast_track_query = checked_fast_track_query(fast_track_query, socket.assigns.layer)
    checked_fast_track_count = count_from_query(checked_fast_track_query, collection)

    socket
    |> assign(:total_count, total_count)
    |> assign(:checked_fast_track_count, checked_fast_track_count)
  end

  defp assign_grscicoll_data(socket) do
    {:ok, grscicoll_data} =
      RestAPI.get_one_collection(socket.assigns.collection.grscicoll_reference)

    assign(socket, :grscicoll_data, grscicoll_data)
  end
end
