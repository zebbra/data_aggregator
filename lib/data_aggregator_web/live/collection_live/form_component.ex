defmodule DataAggregatorWeb.CollectionLive.FormComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Records.Collection

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
        modal_id="collection-modal"
        icon={assigns[:icon]}
        title={@title}
        description={~t"Use this form to manage collections in your database."m}
      />

      <.simple_form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} label={~t"Name"m} placeholder={~t"My Collection"m} />
        <.input field={@form[:owner]} label={~t"Owner"m} placeholder="Brigit Hansson" />
        <.input
          field={@form[:items_to_digitize]}
          label={~t"Total items to digitize"m}
          placeholder="42042"
        />

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            label={~t"Save Collection"m}
          />
          <.button
            color="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
            label={~t"Cancel"m}
            phx-click={JS.exec("data-cancel", to: "#collection-modal")}
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
    Collection
    |> Form.for_create(:create, api: DataAggregator.Records, as: "collection")
    |> to_form()
  end

  defp build_form(%{action: :edit, collection: collection}) do
    collection
    |> Form.for_update(:update, api: DataAggregator.Records, as: "collection")
    |> to_form()
  end

  @impl true
  def handle_event("validate", %{"collection" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"collection" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, collection} ->
          notify_parent({:saved, collection})

          message =
            case socket.assigns.action do
              :new -> ~t"Collection created successfully"m
              :edit -> ~t"Collection updated successfully"m
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
