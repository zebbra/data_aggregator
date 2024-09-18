defmodule DataAggregatorWeb.CollectionLive.ImageUpload.FormComponent do
  @moduledoc """
  Form component for the collection image upload live view.
  """
  use DataAggregatorWeb, :live_component

  alias DataAggregatorWeb.CollectionLive.ImageUpload.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <div class="contents">
        <.live_component
          :if={@action == :new}
          module={Components.Upload}
          id={@id}
          action={@action}
          image_upload={@image_upload}
          collection={@collection}
          meta={@meta}
          current_user={@current_user}
        />
        <%!-- <.live_component
          :if={@action == :edit}
          module={Components.Mapping}
          id={@id}
          action={@action}
          import={@import}
          collection={@collection.id}
          show_validation={@show_validation}
          meta={@meta}
          current_user={@current_user}
        />
        <.live_component
          :if={@action == :summary}
          module={Components.Summary}
          id={@id}
          action={@action}
          import={@import}
          collection={@collection.id}
          meta={@meta}
          busy={@busy}
          current_user={@current_user}
        /> --%>
      </div>
    </div>
    """
  end
end
