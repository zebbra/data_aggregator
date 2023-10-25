defmodule DataAggregatorWeb.CollectionLive.ImportFormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Imports.Collection
  alias DataAggregator.Imports.ImportFile

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:file,
       max_entries: 5,
       accept: ~w(.csv .jpg),
       max_file_size: 80_000_000,
       auto_upload: true
     )
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form_header icon={@icon} title={@title} />

      <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
      <section phx-drop-target={@uploads.file.ref} class="bg-slate-200 p-4 rounded">
        <%!-- render each file entry --%>
        <article :for={entry <- @uploads.file.entries} class="upload-entry">
          <%= entry.client_name %>
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-target={@myself}
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>

          <div>
            <%= for err <- upload_errors(@uploads.file, entry) do %>
              <p class="alert alert-danger"><%= error_to_string(err) %></p>
            <% end %>
          </div>
        </article>
        Drop files here
      </section>

      <.simple_form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_file_input upload={@uploads.file} />

        <:actions>
          <.button
            type="submit"
            class="sm:ml-3 sm:w-auto inline-flex justify-center w-full"
            phx-disable-with={~t"Saving..."m}
          >
            <%= ~t"Save Collection"m %>
          </.button>
          <.button
            variant="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center mt-3 w-full"
            phx-click={JS.exec("data-cancel", to: "#collection-modal")}
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
        class="sm:mx-0 sm:h-10 sm:w-10 flex flex-shrink-0 justify-center items-center mx-auto w-12 h-12 bg-indigo-100 rounded-full"
      >
        <.icon name={@icon} class="w-6 h-6 text-indigo-600" />
      </div>
      <div class={["mt-3 text-center sm:mt-0 sm:text-left", @icon && "sm:ml-4"]}>
        <.dialog_title
          id="collection-modal__title"
          class="dark:text-white text-base font-semibold leading-6 text-gray-900"
        >
          <%= @title %>
        </.dialog_title>
        <.dialog_description
          id="collection-modal__description"
          class="dark:text-gray-400 mt-2 text-sm text-gray-500"
        >
          <%= ~t"Use this form to manage import records in your database."m %>
        </.dialog_description>
      </div>
    </div>
    """
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new}) do
    Collection
    |> Form.for_create(:create, api: DataAggregator.Imports, as: "collection")
    |> to_form()
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    collection = socket.assigns.collection

    import_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, _entry ->
        handle_upload(collection, path)
      end)

    # notify_parent({:saved, socket.assigns.collection})

    {:noreply,
     socket
     |> put_flash(:info, "Imported #{length(import_files)} files")
     |> push_patch(to: socket.assigns.patch)}
  end

  defp handle_upload(collection, path) do
    ImportFile.upload_file(%{collection_id: collection.id, path: path})
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  # defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
