defmodule DataAggregatorWeb.ImportLive.FormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Imports.Import

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
            id="import-modal__title"
            class="text-gray-900 dark:text-white text-base font-semibold leading-6"
          >
            <%= @title %>
          </.dialog_title>
          <.dialog_description
            id="import-modal__description"
            class="text-gray-500 dark:text-gray-400 mt-2 text-sm"
          >
            <%= ~t"Use this form to manage import records in your database."m %>
          </.dialog_description>
        </div>
      </div>

      <.simple_form
        for={@form}
        id="import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:url]} label={~t"URL"m} placeholder={~t"URL"m} />

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            phx-disable-with={~t"Saving..."m}
          >
            <%= ~t"Save Import"m %>
          </.button>
          <.button
            variant="secondary"
            class="mt-3 sm:mt-0 sm:w-auto inline-flex justify-center w-full"
            phx-click={JS.exec("data-cancel", to: "#import-modal")}
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
    Import
    |> Form.for_create(:create, api: DataAggregator.Imports, as: "import")
    |> to_form()
  end

  defp build_form(%{action: :edit, import: import}) do
    import
    |> Form.for_update(:update, api: DataAggregator.Imports, as: "import")
    |> to_form()
  end

  @impl true
  def handle_event("validate", %{"import" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"import" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, course} ->
          notify_parent({:saved, course})

          message =
            case socket.assigns.action do
              :new -> ~t"Import created successfully"m
              :edit -> ~t"Import updated successfully"m
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
