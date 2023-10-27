defmodule DataAggregatorWeb.ImportRecordLive.FormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Imports.ImportRecord

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
          class="sm:mx-0 sm:h-10 sm:w-10 flex items-center justify-center flex-shrink-0 w-12 h-12 mx-auto bg-indigo-100 rounded-full"
        >
          <.icon name={@icon} class="w-6 h-6 text-indigo-600" />
        </div>
        <div class={["mt-3 text-center sm:mt-0 sm:text-left", assigns[:icon] && "sm:ml-4"]}>
          <.dialog_title
            id="import-record-modal__title"
            class="dark:text-white text-base font-semibold leading-6 text-gray-900"
          >
            <%= @title %>
          </.dialog_title>
          <.dialog_description
            id="import-record-modal__description"
            class="dark:text-gray-400 mt-2 text-sm text-gray-500"
          >
            <%= ~t"Use this form to manage import records in your database."m %>
          </.dialog_description>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="import-record-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:unique_qualifier]}
          label={~t"Unique Qualifier"m}
          placeholder={~t"Unique Qualifier"m}
        />

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            phx-disable-with={~t"Saving..."m}
          >
            <%= ~t"Save Import Record"m %>
          </.button>
          <.button
            variant="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
            phx-click={JS.exec("data-cancel", to: "#import-record-modal")}
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
    ImportRecord
    |> Form.for_create(:create, api: DataAggregator.Imports, as: "import_record")
    |> to_form()
  end

  defp build_form(%{action: :edit, import_record: import_record}) do
    import_record
    |> Form.for_update(:update, api: DataAggregator.Imports, as: "import_record")
    |> to_form()
  end

  @impl true
  def handle_event("validate", %{"import_record" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"import_record" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, course} ->
          notify_parent({:saved, course})

          message =
            case socket.assigns.action do
              :new -> ~t"Import Record created successfully"m
              :edit -> ~t"Import Record updated successfully"m
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
