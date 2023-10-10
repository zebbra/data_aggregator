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
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage import records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label="Name" />
        <.input field={@form[:version]} label="Version" />
        <.input field={@form[:collection_id]} label="Collection ID" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Import</.button>
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
              :new -> "Import created successfully"
              :edit -> "Import updated successfully"
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
