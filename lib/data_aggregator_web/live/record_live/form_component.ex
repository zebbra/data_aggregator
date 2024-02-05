defmodule DataAggregatorWeb.RecordLive.FormComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Records.Record

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
      <.modal_header
        modal_id="record-modal"
        icon={assigns[:icon]}
        title={@title}
        description={~t"Use this form to manage records in your database."m}
      />

      <.simple_form
        for={@form}
        id="record-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:mte_material_entity_id]}
          label={~t"Material Entity ID"m}
          placeholder={~t"Material Entity ID"m}
        />

        <.input
          field={@form[:tax_scientific_name]}
          label={~t"Scientific Name"m}
          placeholder={~t"Scientific Name"m}
        />

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            label={~t"Save Record"m}
          />
          <.button
            color="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
            label={~t"Cancel"m}
            phx-click={JS.exec("data-cancel", to: "#record-modal")}
            phx-disable-with
          />
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
    |> Form.for_create(:create, api: DataAggregator.Records, as: "record")
    |> to_form()
  end

  defp build_form(%{action: :edit, record: record}) do
    record
    |> Form.for_update(:update, api: DataAggregator.Records, as: "record")
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
