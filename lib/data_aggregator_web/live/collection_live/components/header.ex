defmodule DataAggregatorWeb.CollectionLive.Components.Header do
  @moduledoc """
  This module contains header components for the collection live view.
  """

  use DataAggregatorWeb, :html

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection_light: 2, busy_action_translation: 1]

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [busy?: 2]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Collection

  attr :collection_id, :any, default: nil
  attr :collection, Collection, default: nil
  attr :busy, :boolean, default: false, doc: "Whether the header action is busy."
  attr :busy_action, :string, default: nil, doc: "The currently busy action on this collection."

  attr :current, :atom,
    default: :records,
    values: ~w(records imports encodings exports publications)a

  attr :current_user, User, required: true

  attr :meta, AshPagify.Meta, default: nil

  def collection_header(%{collection: nil} = assigns) do
    assigns
    |> assign(:collection, get_collection_light(assigns.collection_id, get_actor(assigns)))
    |> assign(:gbif_dataset_base_url, "#{gbif_base_url()}/dataset")
    |> collection_header()
  end

  def collection_header(assigns) do
    show_import_button =
      assigns.current in [:records, :imports] and
        Collection.can_set_importing?(assigns.current_user, assigns.collection)

    show_cancel_button =
      assigns.busy and not assigns.collection.deleting and
        Collection.can_cancel_action?(assigns.current_user, assigns.collection)

    assigns =
      assigns
      |> assign_new(:gbif_dataset_base_url, fn -> "#{gbif_base_url()}/dataset" end)
      |> assign(:show_import_button, show_import_button)
      |> assign(:show_cancel_button, show_cancel_button)

    ~H"""
    <.page_header title_class="px-6 pb-4 pt-1 lg:px-8 md:py-6">
      <:breadcrumbs class="sm:hidden flex items-center justify-between px-6 mt-1 min-h-8">
        <.breadcrumbs
          class="text-sm"
          items={[
            %{label: ~t"Collections"m, link: ~p"/collections"},
            %{label: ~t"Current"m, link: "#"}
          ]}
        />
        <div :if={@show_import_button or @show_cancel_button}>
          <.link
            :if={@show_cancel_button}
            phx-click={JS.push("collection:cancel", value: %{id: @collection.id})}
            data-confirm={~t"Are you sure?"m}
            type="button"
            class="btn btn-error btn-sm"
          >
            <.icon name="hero-stop-solid" class="size-4" />
            <%= ~t"Cancel"m %>
          </.link>
          <.link
            :if={@show_import_button}
            patch={build_path(~p"/collections/#{@collection}/imports/new", @meta)}
            class={[
              "btn btn-primary btn-sm",
              (@busy || is_nil(@meta)) && "btn-disabled"
            ]}
          >
            <%= if importing?(@busy_action) do %>
              <.icon name="hero-cog-6-tooth-solid animate-spin" class="size-4" />
            <% else %>
              <.icon name="hero-arrow-up-tray" class="size-4" />
            <% end %>
            <%= ~t"Add"m %>
          </.link>
        </div>
      </:breadcrumbs>
      <:title>
        <.breadcrumbs
          class="max-sm:hidden text-base-content font-bold text-3xl tracking-tight"
          items={[
            %{label: ~t"Collections"m, link: ~p"/collections"},
            %{label: "#{@collection.name} (#{@collection.code})", link: "#"}
          ]}
        />
        <h2 class="text-base-content text-2xl font-bold tracking-tight max-sm:line-clamp-2 sm:hidden sm:truncate sm:text-3xl">
          <%= "#{@collection.name} (#{@collection.code})" %>
        </h2>
      </:title>
      <:subtitle>
        <.link
          :if={@collection.gbif_dataset_key !== nil}
          class="link link-primary link-hover text-sm/6 flex max-w-4xl items-center gap-x-2 sm:mt-2"
          target="_blank"
          href={"#{@gbif_dataset_base_url}/#{@collection.gbif_dataset_key}"}
        >
          <%= ~t"Show on GBIF" %>
          <.icon name="hero-arrow-top-right-on-square" class="size-4" />
        </.link>

        <div
          :if={@collection.gbif_dataset_key === nil}
          class="text-base-content/60 text-sm/6 flex max-w-4xl items-center gap-x-2 sm:mt-2"
        >
          <%= @collection.code %>
        </div>
      </:subtitle>
      <:actions :if={@show_import_button or @show_cancel_button} class="max-sm:hidden sm:space-x-2">
        <.link
          :if={@show_cancel_button}
          phx-click={JS.push("collection:cancel", value: %{id: @collection.id})}
          data-confirm={~t"Are you sure?"m}
          type="button"
          class="btn btn-error"
        >
          <.icon name="hero-stop-solid" />
          <%= busy_action_translation(@busy_action) %>
        </.link>
        <.link
          :if={@show_import_button}
          patch={build_path(~p"/collections/#{@collection}/imports/new", @meta)}
          class={[
            "btn btn-primary",
            (@busy || is_nil(@meta)) && "btn-disabled"
          ]}
        >
          <%= if importing?(@busy_action) do %>
            <.icon name="hero-cog-6-tooth-solid animate-spin" />
          <% else %>
            <.icon name="hero-arrow-up-tray" />
          <% end %>
          <%= ~t"Import dataset"m %>
        </.link>
      </:actions>
    </.page_header>
    """
  end

  defp importing?(busy_action) do
    busy?("dataset:import", busy_action)
  end
end
