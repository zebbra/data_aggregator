defmodule DataAggregatorWeb.CollectionLive.Publication.FastTrackModal do
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
    {:ok, socket |> assign(:step, 1) |> assign(:agreed, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_count() |> assign_grscicoll_data() |> assign_form()}
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
        phx-submit="publication:submit"
        phx-target={@myself}
        id="publication-form"
        modal
        novalidate
      >
        <.fieldset id="publication" modal>
          <%= body(assigns, 1) %>
          <%= body(assigns, 2) %>
          <%= body(assigns, 3) %>

          <:actions modal>
            <%= footer(assigns) %>
          </:actions>
        </.fieldset>
      </.simple_form>

      <.modal_footer id={@id}></.modal_footer>
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
  def handle_event("publication:submit", %{"publication" => params}, socket) do
    dbg(params)

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

    socket.assigns.form
    |> Form.submit!(params: params)
    |> Publication.enqueue(%{started_by_id: actor.id}, actor: actor)
    |> dbg()

    send(self(), {"fast_track_pub:submit", %{}})

    {:noreply, socket |> assign(:agreed, false) |> push_event("submit:close", %{})}
  end

  defp modal_title(1), do: ~t"Publication of Records"
  defp modal_title(2), do: ~t"Target Dataset"
  defp modal_title(3), do: ~t"Publication summary"

  defp body(assigns, 1) do
    ~H"""
    <div class={unless @step == 1, do: "hidden"}>
      <div id={"#{@id}_inner_body"} class="h-full space-y-4 overflow-y-auto p-6">
        <p class="text-sm">
          <%= mgettext(
            "You are about to send %{count} records to GBIF, making them publicly available. Make sure that the layer you are publishing corresponds to the filters you wish to use. Also, be aware that the records without a value for the ",
            count: format_number(@count)
          ) %>
          <span class="font-bold"><%= ~t"kingdom "m %></span>
          <%= ~t"attribute will not be published."m %>
        </p>

        <%= if @collection.gbif_dataset_key do %>
          <%= "GBIF dataset key: " <> @collection.gbif_dataset_key %>
        <% else %>
          <div class="flex">
            <div class="mr-4 flex-shrink-0">
              <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
            </div>
            <p class="text-sm">
              <%= ~t"This collection has not yet been published. Please choose whether to create a new dataset on GBIF (recommended) or publish your data into an existing dataset (exports)."m %>
            </p>
          </div>
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
            <%= "#{@grscicoll_data["name"]} (#{@grscicoll_data["code"]}) of #{@grscicoll_data["institutionName"]}" %>
          </:item>
          <:item title={~t"Publisher"m}>
            <a
              href="https://www.gbif.org/publisher/9661d20d-86b6-4485-8948-f3c86b022fa7"
              target="_blank"
            >
              SwissNatColl
            </a>
          </:item>
          <:item title={~t"Authors"}>
            <%=  %>
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
            <%= @grscicoll_data["institutionName"] %>
          </:item>
          <:item title={~t"Institution Code"}>
            <%= @grscicoll_data["code"] %>
          </:item>
          <:item title={~t"Address"}>
            <%= inspect(@grscicoll_data["address"]) %>
          </:item>
          <:item title={~t"Originator"}>
            <%= "test" %>
          </:item>
          <:item title={~t"Metadata Provider"}>
            <%= "test" %>
          </:item>
          <:item title={~t"Administrative point of contact"}>
            <%= "test" %>
          </:item>
        </.list>

        <.section_heading
          text={~t"Intellectual property rights"m}
          description={~t"Please choose under what license this publication and dataset is covered."m}
          size="md"
          class="pt-4"
        />
        <div class="grid grid-cols-1">
          <.field
            type="combobox"
            field={@form[:license]}
            label={~t"Institution"m}
            options={[{"CC BY", :cc_by}, {"CC0", :cc0}, {"CC BY-NC", :cc_by_nc}]}
            placeholder={~t"Select institutions"m}
            data-portal="user_modal"
          />
        </div>
      </div>
    </div>
    """
  end

  defp body(assigns, 3) do
    ~H"""
    <div class={unless @step == 3, do: "hidden"}>
      <div id={"#{@id}_inner_body"} class="h-full space-y-4 overflow-y-auto p-6">
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
            <%= ~t"I have read and agree to the"m %>
            <.link
              href="https://swissnatcoll.hp.gbif-staging.org/en/terms"
              target="_blank"
              rel="noopener noreferrer"
              class="text-primary"
            >
              <%= ~t"terms and conditions"m %>
            </.link>
            <%= ~t"and accept responsibility for this publication."m %>
          </p>
        </label>
      </div>
    </div>
    """
  end

  defp footer(%{step: 1} = assigns) do
    ~H"""
    <button type="button" class="btn btn-primary" phx-click="publication:next" phx-target={@myself}>
      <%= ~t"Next"m %>
    </button>
    <button class="btn btn-ghost">
      <%= ~t"Cancel"m %>
    </button>
    """
  end

  defp footer(%{step: 2} = assigns) do
    ~H"""
    <button type="button" class="btn btn-primary" phx-click="publication:next" phx-target={@myself}>
      <%= ~t"Next"m %>
    </button>
    <button type="button" class="btn btn-primary" phx-click="publication:back" phx-target={@myself}>
      <%= ~t"Back"m %>
    </button>
    """
  end

  defp footer(%{step: 3} = assigns) do
    ~H"""
    <button type="submit" class="btn btn-primary" disabled={!@agreed}>
      <%= ~t"Publish"m %>
    </button>
    <button type="button" class="btn btn-ghost" phx-click="publication:back" phx-target={@myself}>
      <%= ~t"Back"m %>
    </button>
    """
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

    dbg(grscicoll_data)

    assign(socket, :grscicoll_data, grscicoll_data)
  end
end
