defmodule DataAggregatorWeb.CollectionLive.Import.Components do
  @moduledoc """
  This module contains components for the collection > import live view.
  """
  use DataAggregatorWeb, :html

  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.Import

  @states AshStateMachine.Info.state_machine_all_states(Import)

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
    <.badge class="pr-3" color={state_color(@state)}>
      <.import_state_icon state={@state} />
      <.import_state_badge_label state={@state} progress={@progress} />
    </.badge>
    """
  end

  attr :state, :atom, required: true, values: @states
  attr :progress, :float, required: false, default: nil

  def import_state_badge_label(%{state: :importing} = assigns) do
    ~H"""
    <.progress max={1} value={@progress} class="progress-info w-16 leading-4" />
    """
  end

  def import_state_badge_label(%{state: :import_queued} = assigns) do
    ~H"""
    <.progress max={1} value={} class="progress-info opacity-75 w-16" />
    """
  end

  def import_state_badge_label(assigns) do
    ~H"""
    <span>{state_translation(@state)}</span>
    """
  end

  def state_color(state) do
    cond do
      state in [:pending] -> "gray"
      state in [:import_queued, :importing] -> "blue"
      state in [:imported] -> "green"
      state in [:failed] -> "red"
    end
  end

  attr :state, :atom, required: true, values: @states

  def import_state_icon(%{state: state} = assigns) do
    {icon, class} = import_state_icon_class(state)
    assigns = assign(assigns, icon: icon, class: class)

    ~H"""
    <.icon name={@icon} class={class_names(["size-5", @class])} />
    """
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

  defp state_translation(state) do
    cond do
      state in [:pending] -> ~t"Pending"m
      state in [:import_queued] -> ~t"Queued"m
      state in [:importing] -> ~t"Importing"m
      state in [:imported] -> ~t"Imported"m
      state in [:failed] -> ~t"Failed"m
    end
  end

  attr :import, Import, required: true
  attr :on_hide, JS, default: %JS{}

  def import_mapping_validation(%{import: import} = assigns) do
    attributes = for cat <- import.missing_mappings, attr <- cat.dwc_attributes, do: {cat, attr}
    assigns = assign(assigns, attributes: attributes)

    ~H"""
    <div :if={@attributes == []} class="alert alert-success bg-success/10 text-success">
      <.icon name="hero-check-circle-solid" />
      <span>{~t"All required attributes are mapped"m}</span>
    </div>

    <div :if={@attributes != []} class="alert alert-error bg-error/10 text-error relative items-start">
      <.icon name="hero-exclamation-triangle" class="mt-1" />

      <div>
        <h3 class="mb-4 flex items-center">
          {~t"The following mappings are required but missing:"m}
        </h3>

        <div class="flex flex-wrap gap-4 text-xs max-sm:justify-center">
          <div :for={{cat, attr} <- @attributes} class="inline-flex">
            <div class="bg-error text-error-content rounded-l px-2 py-1 uppercase">
              {cat.name}
            </div>
            <div class="bg-base-100 rounded-r px-2 py-1">{attr.dwc_field}</div>
          </div>
        </div>
      </div>

      <div class="w-6" />
      <button
        :if={@on_hide != %JS{}}
        type="button"
        phx-click={@on_hide}
        class="btn btn-sm btn-circle btn-ghost absolute top-2 right-2"
        aria-label={~t"close"m}
      >
        <.icon name="hero-x-mark-mini" />
      </button>
    </div>
    """
  end

  attr :column, Import.Column,
    required: true,
    doc: "The name of the attribute prefixed with the category"

  def attribute_badge(assigns) do
    %{column: column} = assigns

    custom = Schema.known_attribute?(column.mapped_to) == false
    category = parse_category(column.mapped_to, custom)

    name =
      if custom,
        do: column.name,
        else: Schema.dwc_field_from_prefixed_attribute_name(column.mapped_to)

    assigns =
      assigns
      |> assign(:category, category)
      |> assign(:custom, custom)
      |> assign(:name, name)

    ~H"""
    <div class="inline-flex text-xs">
      <div class={[
        "rounded-l px-2 py-1 uppercase",
        if(@column.mapped?, do: "bg-info text-info-content", else: "bg-error text-white")
      ]}>
        {@category}
      </div>
      <div class={[
        "rounded-r px-2 py-1",
        if(@column.mapped?,
          do: "bg-info/10 text-base-content",
          else: "bg-error/10 text-error"
        )
      ]}>
        {@name}
      </div>
    </div>
    """
  end

  defp parse_category(_prefixed_attribute, true), do: ~t"Custom Attribute"m

  defp parse_category(prefixed_attribute, _custom) do
    prefixed_attribute
    |> String.split("_")
    |> List.first()
  end
end
