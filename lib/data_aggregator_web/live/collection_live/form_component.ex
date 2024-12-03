defmodule DataAggregatorWeb.CollectionLive.FormComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.CollectionType

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(
        :collection_types,
        CollectionType.get_collection_type_options()
      )
      |> maybe_assign_available_collection_options()

    ~H"""
    <div class="contents">
      <.simple_form
        for={@form}
        id="collection_form"
        novalidate
        phx-target={@myself}
        phx-change="collection:validate"
        phx-submit="collection:save"
        modal
      >
        <.fieldset
          legend={@title}
          text={~t"Use this form to manage collections in your database."m}
          modal
        >
          <.fieldgroup modal>
            <div class="grid grid-cols-1 gap-8 sm:grid-cols-1 sm:gap-4">
              <.field
                type="combobox"
                field={@form[:type]}
                label={~t"Type"m}
                options={@collection_types}
                placeholder={~t"Filter types"m}
                prompt={~t"None"m}
                required
                data-portal="collection_modal"
              />
            </div>
            <div :if={@action == :new} class="grid grid-cols-1 gap-8 sm:grid-cols-1 sm:gap-4">
              <.field
                type="combobox"
                field={@form[:grscicoll_reference]}
                label={~t"GrSciColl Collection"m}
                options={@grscicoll_collections}
                placeholder={~t"Filter Collections"m}
                prompt={~t"None"m}
                required
                data-portal="collection_modal"
              />
            </div>
            <.field
              type="textarea"
              field={@form[:description]}
              label={~t"Description"m}
              placeholder={~t"Description"m}
              rows="4"
            />
          </.fieldgroup>
          <:actions modal>
            <button type="submit" class="btn btn-primary">{submit_label(@action)}</button>
            <button type="button" class="btn btn-ghost" onclick="collection_modal.close()">
              {~t"Cancel"m}
            </button>
          </:actions>
        </.fieldset>
      </.simple_form>
    </div>
    """
  end

  defp submit_label(:new), do: ~t"Create collection"m
  defp submit_label(:edit), do: ~t"Update collection"m

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new, current_user: actor}) do
    Collection
    |> Form.for_create(:create, domain: DataAggregator.Records, as: "collection", actor: actor)
    |> to_form()
  end

  defp build_form(%{action: :edit, collection: collection, current_user: actor}) do
    collection
    |> Form.for_update(:update, domain: DataAggregator.Records, as: "collection", actor: actor)
    |> to_form()
  end

  @impl true
  def handle_event("collection:validate", %{"collection" => params}, socket) do
    form = Form.validate(socket.assigns.form, params)
    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("collection:save", %{"collection" => params}, socket) do
    socket =
      case Form.submit(socket.assigns.form, params: params) do
        {:ok, collection} ->
          message =
            case socket.assigns.action do
              :new -> ~t"Collection created successfully"m
              :edit -> ~t"Collection updated successfully"m
            end

          socket =
            socket
            |> push_event("submit:close", %{})
            |> put_flash(:info, message)

          if socket.assigns.action == :new do
            push_navigate(socket, to: ~p"/collections/#{collection.id}/records")
          else
            push_patch(socket, to: socket.assigns.patch)
          end

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  defp maybe_assign_available_collection_options(%{action: :edit} = assigns) do
    assigns
  end

  defp maybe_assign_available_collection_options(assigns) do
    actor = get_actor(assigns)
    assign(assigns, :grscicoll_collections, Gbif.RestAPI.get_available_collection_options(actor))
  end
end
