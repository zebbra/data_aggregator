defmodule DataAggregatorWeb.CollectionLive.ImportFormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Platform.Collection
  alias DataAggregator.Platform.ImportFile

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
      <.simple_form
        for={@form}
        id="collection-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
        <section
          phx-drop-target={@uploads.file.ref}
          class="mt-2 flex flex-col rounded-md border border-dashed border-gray-900/25 dark:border-white/25 px-6 py-10"
        >
          <div class="flex justify-center">
            <div class="text-center">
              <.icon
                name="hero-photo-mini"
                class="mx-auto h-12 w-12 text-gray-300 dark:text-gray-500"
              />
              <div class="mt-4 flex text-sm leading-6 text-gray-600 dark:text-gray-400">
                <label
                  for={@uploads.file.ref}
                  class="relative cursor-pointer rounded-md bg-white dark:bg-gray-900 font-semibold text-indigo-600 dark:text-white focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 dark:focus-within:ring-offset-gray-900 hover:text-indigo-500"
                >
                  <span><%= ~t"Upload a file"m %></span>
                  <.live_file_input upload={@uploads.file} class="sr-only" />
                </label>
                <p class="pl-1"><%= ~t"or drag and drop"m %></p>
              </div>
              <p class="text-xs leading-5 text-gray-600 dark:text-gray-400">CSV, JPEG, JPG or PNG</p>
            </div>
          </div>

          <div class="mt-4 space-y-2 text-gray-600 dark:text-white">
            <%!-- render each file entry --%>
            <article :for={entry <- @uploads.file.entries}>
              <span class="text-sm"><%= entry.client_name %></span>

              <div class="flex space-x-4">
                <div class="w-full bg-gray-200 rounded-full h-2 mt-2 dark:bg-gray-700">
                  <div
                    class="bg-indigo-600 h-2 rounded-full dark:bg-indigo-500"
                    style={"width: #{entry.progress}%;"}
                  />
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-target={@myself}
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                  class="text-gray-600"
                >
                  &times;
                </button>
              </div>

              <div>
                <%= for err <- upload_errors(@uploads.file, entry) do %>
                  <p class="text-sm text-red-500"><%= error_to_string(err) %></p>
                <% end %>
              </div>
            </article>
          </div>
        </section>

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
          <%= ~t"Use this form to manage collections in your database."m %>
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
    |> Form.for_create(:create, api: DataAggregator.Platform, as: "collection")
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
