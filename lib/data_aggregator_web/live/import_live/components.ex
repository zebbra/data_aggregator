defmodule DataAggregatorWeb.ImportLive.Components do
  use DataAggregatorWeb, :html

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Import
  alias DataAggregatorWeb.ImportLive.Components.MappingForm

  attr :import, Import, required: true
  attr :action, :atom, default: nil

  @states AshStateMachine.Info.state_machine_all_states(Import)

  def import_header(assigns) do
    ~H"""
    <.header>
      <div class="flex items-center justify-between">
        <h1><%= ~t"Import Records"m %></h1>
        <ol class="inline-flex justify-end space-x-4 text-sm">
          <li class="flex items-center space-x-2">
            <span class="text-gray-500 dark:text-gray-400">State:</span>
            <.import_state_badge state={@import.state} />
          </li>
        </ol>
      </div>

      <:subtitle>
        <ol class="flex items-center space-x-4 text-sm">
          <li class="flex items-center space-x-2">
            <.import_attachment import={@import} />
          </li>
        </ol>
      </:subtitle>
    </.header>
    """
  end

  attr :progress, :float, default: nil
  attr :class, :string, default: nil

  def import_progress(assigns) do
    ~H"""
    <progress class={["progress", @class]} value={@progress} max="1" />
    """
  end

  attr :import, Import, required: true

  def import_attachment(assigns) do
    ~H"""
    <div class="flex items-center space-x-1">
      <.attachment_download_badge attachment={@import.attachment} />
      <div class="font-mono text-gray-500 dark:text-gray-400"><%= @import.attachment.filename %></div>
    </div>
    """
  end

  attr :attachment, Attachment, required: true
  attr :class, :string, default: nil

  def attachment_download_badge(assigns) do
    ~H"""
    <.link
      href={@attachment.url}
      class={[
        "inline-flex items-center rounded-md bg-blue-100 px-1.5 py-0.5 text-xs font-medium text-blue-700 opacity-75 hover:opacity-100",
        @class
      ]}
    >
      <.icon name="hero-arrow-down-tray-mini" class="w-3 h-3 mr-1" />
      <%= format_bytes(@attachment.byte_size) %>
    </.link>
    """
  end

  attr :import, Import, required: true
  attr :active, :atom, default: nil

  def import_steps(assigns) do
    ~H"""
    <div class="bg-white dark:bg-gray-900 lg:border-b lg:border-gray-200 lg:dark:border-white/5">
      <nav class="mx-auto" aria-label="Progress">
        <ol
          role="list"
          class="overflow-hidden rounded-md lg:flex lg:justify-items-stretch lg:rounded-none lg:border-gray-200 lg:dark:border-white/5"
        >
          <.import_step
            number={1}
            label="Overview"
            to={~p"/imports/#{@import.id}"}
            active={@active == :show}
          />
          <.import_step
            number={2}
            label="Mapping"
            to={~p"/imports/#{@import.id}/mappings"}
            active={@active == :mappings}
          />
          <.import_step
            number={3}
            label="Confirm"
            to={~p"/imports/#{@import.id}/confirmation"}
            active={@active == :confirmation}
          />
          <.import_step
            number={4}
            label="Records"
            to={~p"/imports/#{@import.id}/records"}
            active={@active == :records}
          />
        </ol>
      </nav>
    </div>
    """
  end

  attr :label, :string
  attr :to, :string
  attr :number, :integer, required: true
  attr :active, :boolean, default: true

  def import_step(assigns) do
    ~H"""
    <li class="relative overflow-hidden lg:flex-1">
      <div class="overflow-hidden rounded-b-md border border-t-0 border-gray-200 dark:border-white/5 lg:border-0">
        <.link patch={@to} class="group">
          <span
            :if={@active}
            class="absolute top-0 left-0 h-full w-1 bg-indigo-600 dark:bg-indigo-500 lg:top-auto lg:bottom-0 lg:h-1 lg:w-full"
            aria-hidden="true"
          >
          </span>
          <span
            class={[
              "absolute top-0 left-0 h-full w-1 bg-transparent lg:top-auto lg:bottom-0 lg:h-1 lg:w-full",
              @active or "group-hover:bg-gray-200 dark:group-hover:bg-white/5"
            ]}
            aria-hidden="true"
          >
          </span>
          <span class="flex items-start items-center px-6 py-5 text-sm font-medium lg:pl-9">
            <span class="flex-shrink-0">
              <span class={[
                "flex h-10 w-10 items-center justify-center rounded-full border-2",
                if(@active, do: "border-indigo-600 dark:border-indigo-500", else: "border-gray-400")
              ]}>
                <span class={["text-md", if(@active, do: "text-indigo-500", else: "text-gray-400 ")]}>
                  <%= @number %>
                </span>
              </span>
            </span>
            <span class="mt-0.5 ml-4 flex min-w-0 flex-col">
              <span class={[
                "text-sm font-semibold",
                if(@active,
                  do: "text-indigo-600 dark:text-indigo-500",
                  else: "text-gray-500 dark:text-gray-400"
                )
              ]}>
                <%= @label %>
              </span>
              <span class="text-sm font-light text-gray-500">Penatibus eu quis ante.</span>
            </span>
          </span>
        </.link>
        <!-- divider -->
        <div
          :if={@number > 1}
          class="absolute inset-0 top-0 left-0 hidden w-3 lg:block"
          aria-hidden="true"
        >
          <svg
            class="h-full w-full text-gray-300 dark:text-white/10"
            viewBox="0 0 12 82"
            fill="none"
            preserveAspectRatio="none"
          >
            <path
              d="M0.5 0V31L10.5 41L0.5 51V82"
              stroke="currentcolor"
              vector-effect="non-scaling-stroke"
            />
          </svg>
        </div>
      </div>
    </li>
    """
  end

  attr :id, :string
  attr :import, Import, required: true

  def import_mapping_form(assigns) do
    %{import: %Import{id: id}} = assigns

    assigns = assigns |> assign_new(:id, fn -> "#{id}_mapping_form" end)

    ~H"""
    <.live_component module={MappingForm} id={@id} import={@import} />
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge(assigns) do
    ~H"""
    <span class={[
      "text-md inline-flex items-center space-x-1.5 rounded-full py-1 pr-3 pl-1.5 font-medium ring-1 ring-inset",
      import_state_badge_class(@state)
    ]}>
      <.import_state_icon state={@state} />
      <.import_state_badge_label state={@state} progress={@progress} />
    </span>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge_label(%{state: :running, progress: progress} = assigns)
      when is_number(progress) do
    ~H"""
    <.import_progress progress={@progress} class="progress-info w-16" />
    """
  end

  def import_state_badge_label(%{state: :queued} = assigns) do
    ~H"""
    <.import_progress progress={} class="opacity-20 w-16" />
    """
  end

  def import_state_badge_label(assigns) do
    ~H"""
    <span><%= @state |> Atom.to_string() |> String.capitalize() %></span>
    """
  end

  def import_state_badge_class(state) do
    case state do
      :pending ->
        "bg-gray-50 text-gray-500 ring-gray-500/10 dark:bg-gray-400/10 dark:text-gray-400 dark:ring-gray-400/20"

      :queued ->
        "bg-yellow-50 text-yellow-800 ring-yellow-600/20 dark:bg-yellow-400/10 dark:text-yellow-500 dark:ring-yellow-400/20"

      :running ->
        "bg-indigo-50 text-indigo-700 ring-indigo-700/10 dark:bg-indigo-400/10 dark:text-indigo-400 dark:ring-indigo-400/30"

      :imported ->
        "bg-green-50 text-green-700 ring-green-600/10 dark:bg-green-500/10 dark:text-green-400 dark:ring-green-500/20"

      :failed ->
        "bg-red-50 text-red-700 ring-red-600/20 dark:bg-red-400/10 dark:text-red-400 dark:ring-red-400/20"

      _ ->
        nil
    end
  end

  attr :state, :atom, required: true, values: @states

  def import_state_icon(%{state: state} = assigns) do
    {icon, class} = state |> import_state_icon_class()
    assigns = assigns |> assign(icon: icon, class: class)

    case icon do
      nil -> ~H()
      _ -> ~H(<.icon name={@icon} class={["h-5 w-5", @class]} />)
    end
  end

  defp import_state_icon_class(state) do
    case state do
      :pending -> {"hero-clock-solid", "opacity-60"}
      :queued -> {"hero-pause-circle-solid", "opacity-60"}
      :running -> {"hero-cog-6-tooth-solid", "opacity-60 animate-spin"}
      :imported -> {"hero-check-circle-solid", "opacity-60"}
      :failed -> {"hero-x-circle-solid", "opacity-60"}
      _ -> {nil, nil}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.ImportLive.Components
    end
  end
end
