defmodule DataAggregatorWeb.CollectionLive.Import.FormComponent do
  @moduledoc """
  Form component for the collection import live view.
  """
  use DataAggregatorWeb, :live_component

  alias DataAggregatorWeb.CollectionLive.Import.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <div :if={@import.state in [nil, :pending]} class="contents">
        <.live_component
          :if={@action == :new}
          module={Components.Upload}
          id={@id}
          action={@action}
          import={@import}
          collection={@collection}
          meta={@meta}
        />
        <.live_component
          :if={@action == :edit}
          module={Components.Mapping}
          id={@id}
          action={@action}
          import={@import}
          collection={@collection.id}
          show_validation={@show_validation}
          meta={@meta}
        />
        <.live_component
          :if={@action == :summary}
          module={Components.Summary}
          id={@id}
          action={@action}
          import={@import}
          collection={@collection.id}
          meta={@meta}
        />
      </div>
      <div :if={@import.state not in [nil, :pending]} class="p-6 lg:px-8">
        <.section_heading
          text={~t"Import was already processed"m}
          description={
            ~t"You are not allowed to process an import twice. Please start again by uploading a new import dataset."m
          }
          size="md"
        />
        <div class="modal-action">
          <button type="button" class="btn btn-primary" onclick="import_modal.close()">
            <%= ~t"Back to imports"m %>
          </button>
        </div>
      </div>
    </div>
    """
  end
end
