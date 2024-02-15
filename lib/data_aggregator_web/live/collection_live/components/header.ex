defmodule DataAggregatorWeb.CollectionLive.Components.Header do
  @moduledoc """
  This module contains header components for the collection live view.
  """

  use DataAggregatorWeb, :live_component
  use DataAggregatorWeb.CollectionLive.Encoding.Components, only: [encoding_state_indicator: 1]

  alias DataAggregator.Records.Collection

  import DataAggregatorWeb.CollectionLive.Helpers,
    only: [get_collection: 1, get_encoding_state: 1]

  attr(:collection_id, :any, default: nil)
  attr(:collection, Collection, default: nil)
  attr(:encoding_state, :atom, default: nil)
  attr(:current, :atom, default: :records, values: ~w(records imports encodings details)a)

  def collection_header(%{collection: nil} = assigns) do
    assigns
    |> assign(:collection, get_collection(assigns.collection_id))
    |> collection_header()
  end

  def collection_header(assigns) do
    assigns =
      assign(assigns, :encoding_state, get_encoding_state(assigns.collection))

    ~H"""
    <.header>
      <:navbar>
        <.secondary_navigation>
          <.secondary_navigation_item
            href={~p"/collections/#{@collection.id}/records"}
            label={~t"Records"m}
            active={@current == :records}
          />
          <.secondary_navigation_item
            href={~p"/collections/#{@collection.id}/imports"}
            label={~t"Imports"m}
            active={@current == :imports}
          />
          <.secondary_navigation_item
            href={~p"/collections/#{@collection.id}/encodings"}
            label={~t"Encodings"m}
            active={@current == :encodings}
          />
          <.secondary_navigation_item
            href={~p"/collections/#{@collection.id}/details"}
            label={~t"Details"m}
            active={@current == :details}
          />
        </.secondary_navigation>
      </:navbar>
      <:breadcrumbs>
        <.breadcrumbs
          class="sm:hidden text-sm"
          items={[
            %{label: ~t"Collections"m, link: ~p"/collections"},
            %{label: ~t"Current"m, link: "#"}
          ]}
        />
      </:breadcrumbs>
      <.breadcrumbs
        class="max-sm:hidden text-lg/6"
        items={[
          %{label: ~t"Collections"m, link: ~p"/collections"},
          %{label: @collection.name, link: "#"}
        ]}
      />
      <span class="sm:hidden"><%= @collection.name %></span>
      <:subtitle>
        <div class="flex items-center gap-x-2 max-sm:pt-2">
          <.encoding_state_badge state={@encoding_state} />
          <%= @collection.description %>
        </div>
      </:subtitle>
      <:actions>
        <.link patch={~p"/collections/new"} class="btn btn-neutral max-sm:btn-sm">
          <.icon name="hero-plus-mini" class="max-sm:hidden" />
          <span class="max-sm:hidden"><%= ~t"Import dataset"m %></span>
          <span class="sm:hidden"><%= ~t"Add"m %></span>
        </.link>
      </:actions>
    </.header>
    """
  end
end
