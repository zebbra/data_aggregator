defmodule DataAggregatorWeb.RecordLive.FormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Data.Record

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
      <div class="sm:flex sm:items-start">
        <div
          :if={assigns[:icon]}
          class="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-indigo-100 sm:mx-0 sm:h-10 sm:w-10"
        >
          <.icon name={@icon} class="h-6 w-6 text-indigo-600" />
        </div>
        <div class={["mt-3 text-center sm:mt-0 sm:text-left", assigns[:icon] && "sm:ml-4"]}>
          <.dialog_title
            id="record-modal__title"
            class="text-gray-900 dark:text-white text-base font-semibold leading-6"
          >
            <%= @title %>
          </.dialog_title>
          <.dialog_description
            id="record-modal__description"
            class="text-gray-500 dark:text-gray-400 mt-2 text-sm"
          >
            <%= ~t"Use this form to manage import records in your database."m %>
          </.dialog_description>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="record-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:materialEntityID]}
          label={~t"MaterialEntityID"m}
          placeholder={~t"MaterialEntityID"m}
        />

        <.input
          field={@form[:scientificName]}
          label={~t"Scientific Name"m}
          placeholder={~t"Scientific Name"m}
        />

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            phx-disable-with={~t"Saving..."m}
          >
            <%= ~t"Save Record"m %>
          </.button>
          <.button
            variant="secondary"
            class="mt-3 sm:mt-0 sm:w-auto inline-flex justify-center w-full"
            phx-click={JS.exec("data-cancel", to: "#record-modal")}
            phx-disable-with
          >
            <%= ~t"Cancel"m %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new}) do
    Record
    |> Form.for_create(:create, api: DataAggregator.Data, as: "record")
    |> to_form()
  end

  defp build_form(%{action: :edit, record: record}) do
    record
    |> Form.for_update(:update, api: DataAggregator.Data, as: "record")
    |> to_form()
  end

  @impl true
  def handle_event("validate", %{"record" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"record" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, course} ->
          notify_parent({:saved, course})

          message =
            case socket.assigns.action do
              :new -> ~t"Record created successfully"m
              :edit -> ~t"Record updated successfully"m
            end

          socket
          |> push_patch(to: socket.assigns.patch)
          |> put_flash(:info, message)

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
