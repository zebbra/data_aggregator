defmodule DataAggregatorWeb.ValidationResponseLive.Components.Summary do
  @moduledoc """
  This module contains components for the validation response live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1, can_run?: 1]

  alias DataAggregator.Records.ValidationResponse

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title_class="!-mr-4 w-full">
        <.stepper current={2} steps={2} />
        <.section_heading
          text={~t"Summary"m}
          description={~t"Please review the summary of your import."m}
          class="mt-4"
        >
          <:actions>
            <div class="flex items-center gap-x-2">
              <span class="text-sm max-sm:hidden">{~t"State:"m}</span>
            </div>
          </:actions>
        </.section_heading>
      </.modal_header>
      <div class="contents">
        <div class="h-full space-y-12 overflow-y-auto px-6 py-8">
          <div class="space-y-4">
            <p class="text-sm">
              {~t"You are about to import"m}
              <span class="font-bold">
                {mgettext(
                  "%{count} %{type}",
                  # TODO: get number
                  count: format_number(15),
                  type: type(@validation_response.type)
                )}
              </span>
              {~t"records."m}
            </p>
            <p class="text-sm">
              {mgettext(
                "Based on the file provided, you are importing %{type} records from:",
                type: type(@validation_response.type)
              )}
            </p>

            <div>
              <.list dense>
                <:item title={~t"Title"m}>
                  test
                </:item>
                <:item title={~t"Title"m}>
                  test
                </:item>
              </.list>
            </div>
          </div>
        </div>
      </div>

      <.modal_footer id={@id}>
        <button
          type="button"
          class="btn btn-primary"
          phx-click="validation_response:run"
          phx-value-id={@validation_response.id}
          phx-target={@myself}
        >
          {~t"Run validation_response"m}
        </button>
        <.link patch={~p"/validation_responses"} type="button" class="btn btn-ghost">
          {~t"Cancel"m}
        </.link>
      </.modal_footer>
    </div>
    """
  end

  defp type(:validated), do: ~t"validated"m
  defp type(:not_validated), do: ~t"not validated"m
end
