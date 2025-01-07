defmodule DataAggregatorWeb.Filters.SimpleFilterForm do
  @moduledoc """
  This module provides the root filter form.

  It takes in the initial filter_form and the target PID to delegate
  all events to.

  ## Example

  ```heex
  <div class="contents">
    <.simple_filter_form
      filter_form={@filter_form}
      count={@count}
      label={@label}
      target={@myself}
      error={@error}
    >
      <:components :let={filter_form}>
        <.filter_form_component
          component={filter_form}
          resource={@meta.resource}
          collapsible_state={@collapsible_state}
          distinct_options={@distinct_options}
          target={@myself}
        />
      </:components>
    </.simple_filter_form>
  </div>
  ```
  """
  use Phoenix.Component
  use DataAggregatorWeb.Gettext

  import DataAggregatorWeb.Components.Form, only: [simple_form: 1]
  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Components.Notification, only: [collapsible_notification: 1]

  alias AshPagify.FilterForm

  attr :filter_form, FilterForm, required: true, doc: "The initial filter form"
  attr :count, :integer, required: true, doc: "The count of the items"
  attr :label, :string, required: true, doc: "The label of the items"

  attr :target, :string,
    required: true,
    doc: "The PID of the component that will receive the event"

  attr :error, :string, doc: "An optional error message"

  slot :components,
    doc: "The components slot of the filter form. This is where all the filter components are rendered."

  def simple_filter_form(assigns) do
    ~H"""
    <div class="contents">
      <div :if={@error} class="px-6 pt-8">
        <.collapsible_notification title="An error has occurred" color="red">
          <:action>
            {~t"Show more"m}
          </:action>
          {@error}
          <ul class="mt-2">
            <li :for={{_, {message, _}} <- FilterForm.errors(@filter_form)}>
              {message}
            </li>
          </ul>
        </.collapsible_notification>
      </div>
      <.simple_form
        :let={filter_form}
        for={@filter_form}
        phx-target={@target}
        phx-change="filter_form:validate"
        phx-submit="filter_form:submit"
        onkeydown="return event.key != 'Enter';"
        class="contents"
      >
        <div class="h-full overflow-y-auto">
          {render_slot(@components, filter_form)}
        </div>
        <:actions class="justify-between" modal>
          <button disabled={@filter_form.valid? == false} type="submit" class="btn btn-primary">
            <.icon
              name="hero-cog-6-tooth-solid animate-spin"
              class="hidden opacity-0 duration-300 ease-linear phx-submit-loading:inline-flex phx-submit-loading:opacity-100"
            /> {mgettext("Show %{count} %{label}", count: @count, label: @label)}
          </button>
          <button
            type="button"
            phx-click="filter_form:reset"
            phx-target={@target}
            class="btn btn-ghost !-mx-4"
          >
            {~t"Clear all"m}
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
