defmodule DataAggregatorWeb.CollectionLive.ConfirmMappingComponent do
  use DataAggregatorWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form_header icon={@icon} title={@title} />
      <.simple_form
        for={@form}
        id="confirm_mapping-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="confirm_mapping"
      >
        <dl class="sm:grid-cols-2 grid grid-cols-1 gap-3 mt-5">
          <div class="sm:p-3 px-4 py-5 overflow-hidden bg-white rounded-lg shadow">
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">100%</dd>
            <dt class="text-sm font-medium text-gray-500 truncate">
              <%= ~t"of your attributes are mapped" %>
            </dt>
          </div>
          <div class="sm:p-3 px-4 py-5 overflow-hidden bg-white rounded-lg shadow">
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">42'359</dd>
            <dt class="text-sm font-medium text-gray-500 truncate">
              <%= ~t"records will be imported"m %>
            </dt>
          </div>
        </dl>

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            phx-disable-with={~t"Confirming your Mapping..."m}
          >
            <%= ~t"Confirm Mapping and Import Records"m %>
          </.button>
          <.button
            variant="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
            phx-click={JS.exec("data-cancel", to: "#confirm-mapping-modal")}
            phx-disable-with
          >
            <%= ~t"Cancel"m %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :icon, :string, default: nil
  attr :title, :string, required: true

  defp form_header(assigns) do
    ~H"""
    <div class="sm:flex sm:items-start">
      <div
        :if={@icon}
        class="sm:mx-0 sm:h-10 sm:w-10 flex items-center justify-center flex-shrink-0 w-12 h-12 mx-auto bg-indigo-100 rounded-full"
      >
        <.icon name={@icon} class="w-6 h-6 text-indigo-600" />
      </div>
      <div class={["mt-3 text-center sm:mt-0 sm:text-left", @icon && "sm:ml-4"]}>
        <.dialog_title
          id="confirm-mapping-modal__title"
          class="dark:text-white text-base leading-6 text-gray-900"
        >
          <%= @title %>
        </.dialog_title>
        <.dialog_description
          id="confirm-mapping-modal__description"
          class="dark:text-gray-400 mt-2 text-sm text-gray-500"
        >
          <%= ~t"Confirm the mapping of your file to our catalog and start importing the records"m %>
        </.dialog_description>
      </div>
    </div>
    """
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new}) do
  end

  @impl true
  def handle_event("confirm_mapping", _params, socket) do
    notify_parent({:confirmed, socket.assigns.import_file})

    {:noreply,
     socket
     |> put_flash(:info, "Confirmed Mapping Successful")
     |> push_patch(to: socket.assigns.patch)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
