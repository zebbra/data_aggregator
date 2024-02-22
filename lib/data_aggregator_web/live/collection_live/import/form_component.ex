defmodule DataAggregatorWeb.CollectionLive.Import.FormComponent do
  @moduledoc """
  Form component for the collection import live view.
  """
  use DataAggregatorWeb, :live_component

  alias DataAggregatorWeb.CollectionLive.Import.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        :if={@action == :new}
        module={Components.Upload}
        id={@id}
        action={@action}
        import={@import}
        collection={@collection}
      />
      <.live_component
        :if={@action == :edit}
        module={Components.Mapping}
        id={@id}
        action={@action}
        import={@import}
        collection={@collection.id}
        show_validation={@show_validation}
      />
      <.live_component
        :if={@action == :summary}
        module={Components.Summary}
        id={@id}
        action={@action}
        import={@import}
        collection={@collection.id}
      />
    </div>
    """
  end
end
