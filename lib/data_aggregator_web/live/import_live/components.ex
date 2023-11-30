defmodule DataAggregatorWeb.ImportLive.Components do
  use DataAggregatorWeb, :html

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Import
  alias DataAggregatorWeb.ImportLive.Components.MappingForm

  @states AshStateMachine.Info.state_machine_all_states(Import)

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

  attr :import, Import, required: false
  attr :rows_valid, :integer, default: nil
  attr :rows_invalid, :integer, default: nil

  def import_validation_result(%{import: import} = assigns) when is_struct(import) do
    assigns
    |> assign(:rows_valid, import.rows_valid_count)
    |> assign(:rows_invalid, import.rows_invalid_count)
    |> assign(:import, nil)
    |> import_validation_result()
  end

  def import_validation_result(assigns) do
    %{rows_valid: valid, rows_invalid: invalid} = assigns

    value =
      case {valid, invalid} do
        {nil, _} -> 0
        {0, _} -> 0
        {_, _} -> valid / (valid + invalid)
      end

    assigns = assign(assigns, :value, value)

    ~H"""
    <div
      class="radial-progress text-primary bg-base-200"
      style={"--value:#{@value * 100};"}
      role="progressbar"
    >
      <%= format_percent(@value) %>
    </div>
    """
  end

  attr :id, :string
  attr :patch, :string, default: nil
  attr :import, Import, required: true

  def import_mapping_form(assigns) do
    %{import: %Import{id: id}} = assigns

    assigns = assign_new(assigns, :id, fn -> "#{id}_mapping_form" end)

    ~H"""
    <.live_component module={MappingForm} id={@id} import={@import} patch={@patch} />
    """
  end

  attr :import, Import, required: false
  attr :state, :atom, required: false, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge(%{import: import} = assigns) when is_struct(import) do
    progress =
      case import.state do
        :importing -> import.import_progress
        :validating -> import.validation_progress
        _ -> nil
      end

    assigns
    |> assign(:state, import.state)
    |> assign(:progress, progress)
    |> assign(:import, nil)
    |> import_state_badge()
  end

  def import_state_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex h-8 items-center space-x-1.5 rounded-full py-1 pr-3 pl-1.5 text-sm font-medium ring-1 ring-inset",
      import_state_badge_class(@state)
    ]}>
      <.import_state_icon state={@state} />
      <.import_state_badge_label state={@state} progress={@progress} />
    </span>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge_label(%{state: :importing} = assigns) do
    ~H"""
    <.import_progress progress={@progress} class="progress-info w-16 leading-4" />
    """
  end

  def import_state_badge_label(%{state: :import_queued} = assigns) do
    ~H"""
    <.import_progress progress={} class="progress-info opacity-75 w-16" />
    """
  end

  def import_state_badge_label(assigns) do
    ~H"""
    <span><%= @state |> Atom.to_string() |> String.capitalize() %></span>
    """
  end

  def import_state_badge_class(state) do
    gray = "bg-neutral-content/50 text-neutral/50 ring-base-content/20"
    blue = "bg-info/10 text-info ring-info/20"
    green = "bg-success/10 text-success ring-success/20"
    red = "bg-error/10 text-error ring-error/20"

    cond do
      state in [:pending] -> gray
      state in [:import_queued, :importing] -> blue
      state in [:imported] -> green
      state in [:failed] -> red
    end
  end

  attr :state, :atom, required: true, values: @states

  def import_state_icon(%{state: state} = assigns) do
    {icon, class} = import_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H(<.icon name={@icon} class={["h-5 w-5", @class]} />)
  end

  defp import_state_icon_class(state) do
    cond do
      state in [:pending] ->
        {"hero-clock-solid", "text-base-content opacity-60"}

      state in [:importing, :import_queued] ->
        {"hero-cog-6-tooth-solid", "text-info animate-spin"}

      state in [:imported] ->
        {"hero-check-circle-solid", "text-success"}

      state in [:failed] ->
        {"hero-x-circle-solid", "text-error"}
    end
  end

  attr :import, Import, required: true

  def import_mapping_validation(%{import: import} = assigns) do
    attributes = for cat <- import.missing_mappings, attr <- cat.attributes, do: {cat, attr}
    assigns = assign(assigns, attributes: attributes)

    ~H"""
    <div :if={@attributes == []} class="alert alert-success bg-success/10 text-success">
      <.icon name="hero-check-circle-solid" />
      <span>All required attributes are mapped</span>
    </div>

    <div :if={@attributes != []} class="alert alert-error bg-error/10 text-error items-start">
      <.icon name="hero-exclamation-triangle" class="mt-1" />

      <div>
        <h3 class="mb-4 flex items-center">
          The following mappings are required but missing:
        </h3>

        <div class="flex flex-wrap gap-4 text-xs">
          <div :for={{cat, attr} <- @attributes} class="inline-flex">
            <div class="bg-error text-error-content rounded-l px-2 py-1 uppercase">
              <%= cat.name %>
            </div>
            <div class="bg-base-100 rounded-r px-2 py-1"><%= attr.name %></div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.ImportLive.Components
    end
  end
end
