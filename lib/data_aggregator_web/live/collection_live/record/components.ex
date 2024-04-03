defmodule DataAggregatorWeb.CollectionLive.Record.Components do
  @moduledoc """
  This module contains components for the collection > record live view.
  """
  use DataAggregatorWeb, :html

  attr :state, :atom,
    required: true,
    values: [:publishing, :in_publication, :published, :stale, :failed]

  def publication_status_badge(assigns) do
    case assigns.state do
      :publishing ->
        ~H"""
        <.badge class="px-2 tooltip tooltip-info" color="blue" data-tip={~t"Publication in progress"m}>
          <.icon name="hero-cog-6-tooth-solid" class="size-5 shrink-0 animate-spin" />
          <span class="px-1.5"><%= ~t"Publishing"m %></span>
        </.badge>
        """

      :in_publication ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-info"
          color="blue"
          data-tip={~t"Record is in the publication pipeline - no further action required"m}
        >
          <.icon name="hero-information-circle-solid" class="size-5 shrink-0" />
          <span class="px-1.5"><%= ~t"In Publication"m %></span>
        </.badge>
        """

      :published ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-success"
          color="green"
          data-tip={~t"Record was successful published"m}
        >
          <.icon name="hero-check-circle-solid" class="size-5 shrink-0" />
          <span class="px-1.5"><%= ~t"Published"m %></span>
        </.badge>
        """

      :stale ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-warning"
          color="orange"
          data-tip={~t"Record was changed after publishing it and has to be republished"m}
        >
          <.icon name="hero-exclamation-triangle-solid" class="size-5 shrink-0" />
          <span class="px-1.5"><%= ~t"Stale"m %></span>
        </.badge>
        """

      :failed ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-error"
          color="red"
          data-tip={~t"Record was changed after publishing it and has to be republished"m}
        >
          <.icon name="hero-x-circle-solid" class="size-5 shrink-0" />
          <span class="px-1.5"><%= ~t"Failed"m %></span>
        </.badge>
        """

      _ ->
        ~H"""
        <.badge
          class="px-2 tooltip tooltip-ghost"
          color="gray"
          data-tip={~t"No publication information available. Publish the collection to see the status"m}
        >
          <.icon name="hero-question-mark-circle-solid" class="size-5 shrink-0" />
          <span class="px-1.5"><%= ~t"Not Published"m %></span>
        </.badge>
        """
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Record.Components
    end
  end
end
