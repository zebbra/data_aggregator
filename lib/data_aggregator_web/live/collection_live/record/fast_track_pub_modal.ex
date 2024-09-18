defmodule DataAggregatorWeb.CollectionLive.Record.FastTrackPubModal do
  @moduledoc false

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [filter_map: 3]

  alias DataAggregator.Records.Record

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :agreed, false)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_count()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title={~t"Publication summary"} />
      <div id={"#{@id}_inner_body"} class="h-full space-y-4 overflow-y-auto p-6">
        <p class="mb-4 text-sm">
          <%= mgettext(
            "You are about to publish %{count} records to the official GBIForg portal, making them publicly available.",
            count: format_number(@count)
          ) %>
        </p>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-sm">
            <%= ~t"In addition to the filters provided, we also add the restriction for all records that the"m %>
            <span class="font-bold"><%= ~t"kingdom  "m %></span>
            <%= ~t"attribute must be set."m %>
          </p>
        </div>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-exclamation-triangle-mini" class="size-6 text-warning" />
          </div>
          <p class="text-sm">
            <%= ~t"This action is irreversible. It is your responsibility to ensure that no sensitive information is included in the data being shared. Should you need to remove any records after publication, you will need to contact the GBIF Secretariat directly for assistance, as deletions cannot be handled independently."m %>
          </p>
        </div>
        <div class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
          </div>
          <p class="text-sm">
            <%= ~t"The publisher of your data on GBIF is SwissNatColl, but your institution retains ownership of the data at all times."m %>
          </p>
        </div>
        <div :if={@count == 0} class="flex">
          <div class="mr-4 flex-shrink-0">
            <.icon name="hero-x-circle-mini" class="size-6 text-error" />
          </div>
          <p class="text-sm">
            <%= ~t"There are no records availabe for publication. Either your records do not have set the kingdom attribute or you have applied a too restrictive filter."m %>
          </p>
        </div>
        <label class="flex" phx-click="toggle:agree">
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
        <p class="text-base-content/60 mt-4 text-sm">
          <%= ~t"By clicking"m %>
          <span class="text-base-content italic"><%= ~t"Publish"m %></span>
          <%= ~t"the publication will be triggered. No further action is required. Please note that this process may take some time."m %>
        </p>
      </div>
      <.modal_footer id={@id}>
        <form method="dialog" class="contents">
          <button
            type="submit"
            value="confirm"
            class="btn btn-primary"
            disabled={@busy or !@agreed or @count == 0}
          >
            <%= ~t"Publish"m %>
          </button>
          <button class="btn btn-ghost">
            <%= ~t"Cancel"m %>
          </button>
        </form>
      </.modal_footer>
    </div>
    """
  end

  defp assign_count(socket) do
    %{collection: collection, meta: %{ash_pagify: ash_pagify}} = socket.assigns
    actor = get_actor(socket)
    collection = Ash.load!(collection, [:fast_track_query], lazy?: true, actor: actor)

    fast_track_query = filter_map(ash_pagify, collection.fast_track_query, socket.assigns.layer)
    count_query = AshPagify.query_for_filters_map(Record, fast_track_query)

    assign(socket, :count, Ash.count!(count_query))
  end
end
