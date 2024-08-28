defmodule DataAggregatorWeb.CollectionLive.Components.Header do
  @moduledoc """
  This module contains header components for the collection live view.
  """

  use DataAggregatorWeb, :html

  import DataAggregator.Accounts.Helpers
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection: 2]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Collection

  attr :collection_id, :any, default: nil
  attr :collection, Collection, default: nil
  attr :disabled, :boolean, default: false, doc: "Whether the header action is disabled."
  attr :busy, :boolean, default: false, doc: "Whether the header action is busy."

  attr :current, :atom,
    default: :records,
    values: ~w(records imports encodings exports publications)a

  attr :current_user, User, required: true

  attr :meta, AshPagify.Meta, default: nil

  def collection_header(%{collection: nil} = assigns) do
    assigns
    |> assign(:collection, get_collection(assigns.collection_id, get_actor(assigns)))
    |> assign(:gbif_dataset_base_url, "#{gbif_base_url()}/dataset")
    |> collection_header()
  end

  def collection_header(assigns) do
    assigns = assign_new(assigns, :gbif_dataset_base_url, fn -> "#{gbif_base_url()}/dataset" end)

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
          :if={
            @current in [:records, :imports] and
              has_role?(@current_user, ["data_administrator", "admin"])
          }
          patch={build_path(~p"/collections/#{@collection}/imports/new", @meta)}
          class={[
            "btn btn-primary btn-sm",
            @disabled && "btn-disabled"
          ]}
        >
          <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" class="size-4" />
          <.icon :if={@busy == false} name="hero-arrow-up-tray" class="size-4" />
          <%= ~t"Add"m %>
        </.link>
      </:breadcrumbs>
      <:title>
        <.breadcrumbs
          class="max-sm:hidden text-base-content font-bold text-3xl tracking-tight"
          items={[
            %{label: ~t"Collections"m, link: ~p"/collections"},
            %{label: "#{@collection.code} - #{@collection.name}", link: "#"}
          ]}
        />
        <h2 class="text-base-content text-2xl font-bold tracking-tight max-sm:line-clamp-2 sm:hidden sm:truncate sm:text-3xl">
          <%= @collection.code %> - <%= @collection.name %>
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
      <:actions
        :if={
          @current in [:records, :imports] and
            has_role?(@current_user, ["data_administrator", "admin"])
        }
        class="max-sm:hidden"
      >
        <.link
          patch={build_path(~p"/collections/#{@collection}/imports/new", @meta)}
          class={[
            "btn btn-primary",
            @disabled && "btn-disabled"
          ]}
        >
          <.icon :if={@busy} name="hero-cog-6-tooth-solid animate-spin" />
          <.icon :if={@busy == false} name="hero-arrow-up-tray" />
          <%= ~t"Import dataset"m %>
        </.link>
      </:actions>
    </.page_header>
    """
  end
end
