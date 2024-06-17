defmodule DataAggregatorWeb.CollectionLive.Components.Header do
  @moduledoc """
  This module contains header components for the collection live view.
  """

  use DataAggregatorWeb, :html
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_indicator: 1]

  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]

  alias DataAggregator.Records.Collection

  @gbif_dataset_base_url :data_aggregator
                         |> Application.compile_env(:gbif, [])
                         |> Keyword.get(:dataset_url)

  attr :collection_id, :any, default: nil
  attr :collection, Collection, default: nil

  attr :current, :atom,
    default: :records,
    values: ~w(records imports encodings exports publications)a

  attr :meta, Pagify.Meta, default: nil

  def collection_header(%{collection: nil} = assigns) do
    assigns
    |> assign(:collection, get_collection(assigns.collection_id))
    |> assign(:gbif_dataset_base_url, @gbif_dataset_base_url)
    |> collection_header()
  end

  def collection_header(assigns) do
    assigns = assign_new(assigns, :gbif_dataset_base_url, fn -> @gbif_dataset_base_url end)

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
        <.link
          :if={@current in [:records, :imports]}
          patch={build_path(~p"/collections/#{@collection}/imports/new", @meta)}
          class="btn btn-primary btn-sm"
        >
          <.icon name="hero-arrow-up-tray" class="size-4" />
          <%= ~t"Add"m %>
        </.link>
      </:breadcrumbs>
      <:title>
        <.breadcrumbs
          class="max-sm:hidden text-base-content font-bold text-3xl tracking-tight"
          items={[
            %{label: ~t"Collections"m, link: ~p"/collections"},
            %{label: @collection.name, link: "#"}
          ]}
        />
      </:title>
      <:subtitle>
        <div
          :if={@collection.gbif_dataset_key !== nil}
          class="text-base-content/60 text-sm/6 line-clamp-3 flex max-w-4xl items-center gap-x-2 sm:mt-2"
        >
          <.link
            class="tooltip tooltip-bottom inline-flex items-center text-primary gap-x-2"
            target="_blank"
            data-tip={~t"Open dataset on GBIF"}
            href={"#{@gbif_dataset_base_url}/#{@collection.gbif_dataset_key}"}
          >
            <%= @collection.code %> | <%= @collection.name %>
            <.icon name="hero-arrow-top-right-on-square" class="size-4" />
          </.link>
        </div>

        <div
          :if={@collection.gbif_dataset_key === nil}
          class="text-base-content/60 text-sm/6 line-clamp-3 flex max-w-4xl items-center gap-x-2 sm:mt-2"
        >
          <%= @collection.code %> - <%= @collection.name %>
        </div>
      </:subtitle>
      <:actions :if={@current in [:records, :imports]} class="max-sm:hidden">
        <.link
          patch={build_path(~p"/collections/#{@collection}/imports/new", @meta)}
          class="btn btn-primary"
        >
          <.icon name="hero-arrow-up-tray" />
          <%= ~t"Import dataset"m %>
        </.link>
      </:actions>
    </.page_header>
    """
  end
end
