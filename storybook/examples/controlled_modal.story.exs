defmodule Storybook.Examples.ControlledModal do
  use PhoenixStorybook.Story, :example
  use DataAggregatorWeb.Components
  use DataAggregatorWeb.Blocks

  alias Phoenix.LiveView.JS

  def doc do
    "An example of how to use a modal in a controlled way."
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       show: false
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <button type="button" class="btn btn-neutral" phx-click="show">
        Open modal
      </button>

      <.modal :if={@show} id="modal" show responsive backdrop={false} on_cancel={JS.push("hide")}>
        <.simple_form :let={f} for={%{}} as={:user} phx-submit={JS.push("save")}>
          <.fieldset
            legend="Shipping details"
            text="Without this your odds of getting your order are low."
          >
            <.fieldgroup>
              <div class="grid grid-cols-1 gap-8 sm:grid-cols-2 sm:gap-4">
                <.field field={f[:first_name]} label="First name" required />
                <.field field={f[:last_name]} label="Last name" required />
              </div>

              <.field field={f[:street_address]} label="Street address" required />
              <div class="grid grid-cols-1 gap-8 sm:grid-cols-3 sm:gap-4">
                <div class="sm:col-span-2">
                  <.field
                    field={f[:country]}
                    label="Country"
                    description="We currently only ship to North America."
                    required
                    type="select"
                    options={["Canada", "Mexico", "United States"]}
                  />
                </div>
                <.field field={f[:postal_code]} label="Postal code" required />
              </div>
              <.field
                field={f[:notes]}
                label="Delivery notes"
                description="If you have a tiger, we'd like to know about it."
                type="textarea"
                required
              />
            </.fieldgroup>
          </.fieldset>
          <:actions>
            <button type="button" class="btn btn-ghost" onclick="modal.close()">
              Cancel
            </button>
            <button type="reset" class="btn btn-ghost">Reset</button>
            <button type="submit" class="btn btn-neutral">Save user</button>
          </:actions>
        </.simple_form>
      </.modal>

      <.flash_group flash={@flash} />
    </section>
    """
  end

  @impl true
  def handle_event("save", %{"user" => params}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, inspect(params))
     |> assign(:show, false)}
  end

  @impl true
  def handle_event("show", _, socket) do
    {:noreply, assign(socket, :show, true)}
  end

  @impl true
  def handle_event("hide", _, socket) do
    {:noreply, assign(socket, :show, false)}
  end
end
