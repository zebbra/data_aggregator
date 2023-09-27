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
      <.dialog_title id="import-modal__title" class="text-zinc-800 text-base font-semibold leading-9">
        <%= @title %>
      </.dialog_title>
      <.dialog_description
        id="import-modal__description"
        class="text-zinc-600 dark:text-gray-400 mt-2 text-sm leading-6"
      >
        <%= ~t"Use this form to manage import records in your database."m %>
      </.dialog_description>

      <.simple_form
        for={@form}
        id="import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:url]} label="URL" />

        <:actions>
          <.button phx-disable-with={~t"Saving..."m}><%= ~t"Save Import"m %></.button>
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
