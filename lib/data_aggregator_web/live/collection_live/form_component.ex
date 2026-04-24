defmodule DataAggregatorWeb.CollectionLive.FormComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.CollectionType
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def update(assigns, socket) do
    first_update? = not Map.has_key?(socket.assigns, :form)

    socket = socket |> assign(assigns) |> assign_form()

    socket =
      if first_update? and assigns.action == :new do
        socket
        |> assign(:grscicoll_collections, AsyncResult.loading())
        |> start_async_grscicoll_collections()
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :collection_types, CollectionType.get_collection_type_options())

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
          text={~t"Use this form to manage datasets in your database."m}
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
              <.async_data :let={grscicoll_collections} async_result={@grscicoll_collections}>
                <:loading>
                  <.skeleton class="h-10 w-full" />
                </:loading>
                <:failed>
                  <div class="flex">
                    <div class="mr-4 shrink-0">
                      <.icon name="hero-x-circle-mini" class="size-6 text-error" />
                    </div>
                    <p class="text-sm">
                      {~t"Failed to load GrSciColl collections. Please close the modal and try again."m}
                    </p>
                  </div>
                </:failed>
                <.field
                  type="combobox"
                  field={@form[:grscicoll_reference]}
                  label={~t"GrSciColl Collection"m}
                  options={grscicoll_collections}
                  placeholder={~t"Filter Datasets"m}
                  prompt={~t"None"m}
                  required
                  data-portal="collection_modal"
                />
              </.async_data>
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

  defp submit_label(:new), do: ~t"Create dataset"m
  defp submit_label(:edit), do: ~t"Update dataset"m

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
              :new -> ~t"Dataset created successfully"m
              :edit -> ~t"Dataset updated successfully"m
            end

          socket =
            socket
            |> push_event("submit:close", %{})
            |> put_flash(:info, message)

          if socket.assigns.action == :new do
            push_navigate(socket, to: ~p"/datasets/#{collection.id}/records")
          else
            push_navigate(socket, to: socket.assigns.patch)
          end

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  defp start_async_grscicoll_collections(socket) do
    actor = get_actor(socket)

    assign_async(socket, :grscicoll_collections, fn ->
      {:ok, %{grscicoll_collections: Gbif.RestAPI.get_available_collection_options(actor)}}
    end)
  end
end
