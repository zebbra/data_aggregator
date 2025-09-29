defmodule DataAggregatorWeb.AdministrationLive.ValidationResponse.FormComponent do
  @moduledoc """
  Form component for the validation response live view.
  """
  use DataAggregatorWeb, :live_component

  alias DataAggregatorWeb.AdministrationLive.ValidationResponse.Components

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <div :if={@validation_response.state in [nil, :pending]} class="contents">
        <.live_component
          :if={@action in [:new]}
          module={Components.Upload}
          id={@id}
          action={@action}
          validation_response={@validation_response}
          current_user={@current_user}
        />
        <.live_component
          :if={@action in [:summary]}
          module={Components.Summary}
          id={@id}
          action={@action}
          validation_response={@validation_response}
          current_user={@current_user}
        />
      </div>
    </div>
    """
  end
end
