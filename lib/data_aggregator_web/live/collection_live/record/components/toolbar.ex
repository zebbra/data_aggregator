defmodule DataAggregatorWeb.CollectionLive.Record.Components.Toolbar do
  @moduledoc false
  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.CollectionLive.Record.Helpers, only: [busy?: 2, path_helper: 3]
  import DataAggregatorWeb.Components.Dropdown, only: [dropdown: 1]
  import DataAggregatorWeb.Components.Field, only: [custom_field: 1]
  import DataAggregatorWeb.Components.Form, only: [simple_form: 1]
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Components.Input, only: [input: 1]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Records.Collection
  alias Phoenix.LiveView.JS

  @actions [
    {"export", "hero-arrow-down-tray", "collection:export"},
    {"encode", "hero-puzzle-piece", "encode:toggle"},
    {"publish", "hero-globe-alt", "fast_track_pub:toggle"},
    {"approve", "hero-check-badge", "approval_pub:toggle"}
  ]

  attr :search, Phoenix.HTML.Form, default: nil, doc: "The search form"
  attr :meta, AshPagify.Meta, default: nil, doc: "The ash_pagify meta object"
  attr :collection, Collection, required: true, doc: "The collection"
  attr :records_count, :integer, required: true, doc: "The total number of records"
  attr :filters_count, :integer, required: true, doc: "The number of active filters"
  attr :busy, :boolean, required: true, doc: "Whether the actions are busy"
  attr :busy_action, :string, required: true, doc: "The busy action"
  attr :layer, :string, required: true, doc: "The current layer"
  attr :current_user, User, required: true, doc: "The current user"

  def toolbar(assigns) do
    assigns = assign(assigns, :actions, @actions)

    ~H"""
    <div :if={@records_count > 0} class="flex justify-between px-6 pb-6 lg:px-8">
      <%!-- Search and filter --%>
      <div class="join max-sm:w-full">
        <%!-- Full-text search  --%>
        <div class="flex-1">
          <div>
            <.simple_form
              for={@search}
              class="w-full"
              phx-change="search:reset"
              phx-submit="search:apply"
              phx-window-keydown={JS.focus(to: "#search_query")}
              phx-key="/"
              phx-debounce="300"
            >
              <.custom_field
                field={@search[:query]}
                disabled={is_nil(@meta)}
                placeholder={~t"Search"}
                class="input input-bordered join-item flex-row items-center gap-2 max-sm:text-base sm:inline-flex"
              >
                <:content :let={field}>
                  <input
                    :if={@search[:query].value != ""}
                    value=""
                    type="reset"
                    class="text-base-content/50 hero-x-mark size-5 !bg-current cursor-pointer hover:text-base-content/90 phx-submit-loading:hidden phx-change-loading:hidden"
                    aria-hidden="true"
                  />
                  <input
                    :if={@search[:query].value == ""}
                    value=""
                    type="submit"
                    name="hero-magnifying-glass"
                    class="text-base-content/50 hero-magnifying-glass size-5 !bg-current cursor-pointer hover:text-base-content/90 phx-submit-loading:hidden phx-change-loading:hidden"
                  />
                  <.icon
                    name="hero-cog-6-tooth animate-spin"
                    class="size-5 text-base-content/50 hidden phx-submit-loading:block phx-change-loading:block"
                  />
                  <.input {field} class="max-sm:w-0" inside />
                </:content>
              </.custom_field>
            </.simple_form>
          </div>
        </div>

        <%!-- Column select --%>
        <%!-- <button
            data-tip={~t"Columns"m}
            class="join-item btn btn-outline border-base-content/20 btn-disabled border-y max-sm:btn-square sm:max-md:tooltip"
          >
            <.icon name="hero-table-cells" />
            <span class="max-md:hidden"><%= ~t"Columns"m %></span>
          </button> --%>

        <%!-- Layers --%>
        <.dropdown id="layer" class="dropdown-end">
          <:summary>
            <summary
              disabled={is_nil(@meta)}
              class="join-item btn btn-outline border-base-content/20 max-lg:btn-square max-lg:inline-flex sm:max-lg:tooltip"
              data-tip={current_layer_label(@layer)}
            >
              <.icon name="hero-bars-2" />
              <span class="max-lg:hidden">{~t"Layers"m}</span>
            </summary>
          </:summary>
          <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-10 mt-14 w-56 gap-1 border p-2 shadow-2xl">
            <li>
              <.link patch={path_helper(@collection.id, "encoding", @meta)}>
                <input type="radio" name="layer" checked={@layer in ["encoding", "approval"]} />
                <span class="font-[sans-serif]">{current_layer_label("encoding")}</span>
              </.link>
            </li>
            <li>
              <.link patch={path_helper(@collection.id, "import", @meta)}>
                <input type="radio" name="layer" checked={@layer == "import"} />
                <span class="font-[sans-serif]">{current_layer_label("import")}</span>
              </.link>
            </li>
            <div class="border-black-white/10 border-b"></div>
            <li>
              <.link patch={
                if @layer == "approval" do
                  path_helper(@collection.id, "encoding", @meta)
                else
                  path_helper(@collection.id, "approval", @meta)
                end
              }>
                <input type="checkbox" name="approval" checked={@layer == "approval"} />
                <span class="font-[sans-serif]">{current_layer_label("approval")}</span>
              </.link>
            </li>
          </ul>
        </.dropdown>

        <%!-- Filter --%>
        <div class="indicator">
          <span :if={@filters_count > 0} class="indicator-item badge badge-primary">
            {@filters_count}
          </span>
          <button
            phx-click="filter_form:toggle"
            class={[
              if(@filters_count == 0,
                do: "border-base-content/20",
                else: "border-primary sm:outline-primary sm:outline sm:hover:outline-none"
              ),
              "join-item btn btn-outline border-y max-lg:btn-square sm:!rounded-e-lg sm:max-lg:tooltip"
            ]}
            data-tip={~t"Filters"m}
            disabled={is_nil(@meta)}
          >
            <.icon name="hero-adjustments-vertical" />
            <span class="max-lg:hidden">{~t"Filters"m}</span>
          </button>
        </div>

        <%!-- Join actions buttons (< sm) --%>
        <.dropdown id="actions-sm" class="dropdown-end sm:hidden">
          <:summary>
            <summary
              disabled={@busy or is_nil(@meta)}
              class="join-item btn btn-outline border-base-content/20 !rounded-e-lg btn-square sm:hidden"
              data-tip={~t"Actions"m}
            >
              <.icon name={if @busy, do: "hero-cog-6-tooth-solid animate-spin", else: "hero-bars-3"} />
            </summary>
          </:summary>
          <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-10 mt-14 w-44 gap-1 border p-2 shadow-2xl">
            <li :for={{label, icon, action} <- @actions}>
              <button
                phx-click={action}
                disabled={@busy or is_nil(@meta) or not action_allowed?(@current_user, label)}
              >
                <.icon name={icon} class="size-5" />
                <span class="font-[sans-serif]">{action_label(label)}</span>
              </button>
            </li>
          </ul>
        </.dropdown>
      </div>

      <%!-- Dropdown action buttons (sm-xl) --%>
      <.dropdown id="actions-md" class="dropdown-end max-sm:hidden 2xl:hidden">
        <:summary>
          <summary
            disabled={@busy or is_nil(@meta)}
            class="btn btn-outline border-base-content/20 max-sm:btn-square"
          >
            <.icon name={if @busy, do: "hero-cog-6-tooth-solid animate-spin", else: "hero-bars-3"} />
            <span class="max-sm:hidden">{~t"Actions"m}</span>
          </summary>
        </:summary>
        <ul class="dropdown-content menu menu-sm bg-base-200 rounded-box border-black-white/10 top-px z-20 mt-14 w-44 gap-1 border p-2 shadow-2xl">
          <li :for={{label, icon, action} <- @actions}>
            <button
              phx-click={action}
              disabled={@busy or is_nil(@meta) or not action_allowed?(@current_user, label)}
            >
              <.icon name={icon} class="size-5" />
              <span class="font-[sans-serif]">{action_label(label)}</span>
            </button>
          </li>
        </ul>
      </.dropdown>

      <%!-- Inline action buttons (> 2xl) --%>
      <div id="actions-xl" class="join max-2xl:hidden">
        <button
          :for={{label, icon, action} <- @actions}
          class="join-item btn btn-outline border-base-content/20"
          phx-click={action}
          disabled={@busy or is_nil(@meta) or not action_allowed?(@current_user, label, @collection)}
        >
          <.icon :if={busy?(action, @busy_action) == false} name={icon} />
          <.icon :if={busy?(action, @busy_action)} name="hero-cog-6-tooth-solid animate-spin" />
          <span class="max-sm:hidden">{action_label(label)}</span>
        </button>
      </div>
    </div>
    """
  end

  defp current_layer_label("approval"), do: ~t"Approval Layer"m
  defp current_layer_label("encoding"), do: ~t"Encoding Layer"m
  defp current_layer_label("import"), do: ~t"Import Layer"m

  defp action_allowed?(user, "export", collection), do: Collection.can_set_exporting?(user, collection)

  defp action_allowed?(user, "encode", collection), do: Collection.can_enqueue_encoding?(user, collection, %{})

  defp action_allowed?(user, "publish", collection), do: Collection.can_set_fast_track_publishing?(user, collection)

  defp action_allowed?(user, "approve", collection), do: Collection.can_set_approving?(user, collection)

  defp action_allowed?(_, _), do: false

  def action_label("export"), do: ~t"Export"m
  def action_label("encode"), do: ~t"Encode"m
  def action_label("publish"), do: ~t"Publish"m
  def action_label("approve"), do: ~t"Approve"m
end
