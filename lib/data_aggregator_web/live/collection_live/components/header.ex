defmodule DataAggregatorWeb.CollectionLive.Components.Header do
  @moduledoc """
  This module contains header components for the collection live view.
  """

  use DataAggregatorWeb, :html
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_indicator: 1]

  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 1]

  alias DataAggregator.Records.Collection

  attr :collection_id, :any, default: nil
  attr :collection, Collection, default: nil

  attr :current, :atom,
    default: :records,
    values: ~w(records imports encodings exports publications details)a

  def collection_header(%{collection: nil} = assigns) do
    assigns
    |> assign(:collection, get_collection(assigns.collection_id))
    |> collection_header()
  end

  def collection_header(assigns) do
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
          patch={~p"/collections/#{@collection}/imports/new"}
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
        <h2 class="text-base-content text-2xl font-bold max-sm:line-clamp-2 sm:hidden sm:truncate sm:text-3xl sm:tracking-tight">
          <%= @collection.code %> - <%= @collection.name %>
        </h2>
      </:title>
      <:subtitle>
        <div class="text-base-content/60 text-sm/6 line-clamp-3 flex max-w-4xl items-center gap-x-2 sm:mt-2">
          <%= @collection.code %>
        </div>
      </:subtitle>
      <:actions :if={@current in [:records, :imports]} class="max-sm:hidden">
        <.link patch={~p"/collections/#{@collection}/imports/new"} class="btn btn-primary">
          <.icon name="hero-arrow-up-tray" />
          <%= ~t"Import dataset"m %>
        </.link>
      </:actions>
    </.page_header>
    """
  end
end
