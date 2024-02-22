defmodule DataAggregatorWeb.CollectionLive.Import.Components.Summary do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Import.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

  alias DataAggregator.Records.Import

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.stepper
        current={current_step(@action)}
        links={[nil, ~p"/collections/#{@collection}/imports/#{@import}/edit", nil]}
      />
      <div class="space-y-8">
        <.heading
          title={~t"Summary"m}
          subtitle={~t"Please review the summary of your import."m}
          class="border-b border-black-white/10 py-4"
        />
      </div>
      <div class="modal-action">
        <button
          :if={@import.state == :pending}
          type="button"
          class="btn btn-primary"
          phx-click="import:run"
          phx-value-id={@import.id}
          phx-target={@myself}
        >
          <%= ~t"Run import"m %>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("import:run", %{"id" => id}, socket) do
    id |> Import.get_by_id!() |> Import.enqueue_import!()

    {:noreply,
     socket
     |> put_flash(:info, ~t"Import started in background"m)
     |> push_navigate(to: ~p"/collections/#{socket.assigns.collection}/imports")}
  end
end
