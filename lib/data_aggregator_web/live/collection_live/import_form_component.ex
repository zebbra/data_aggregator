defmodule DataAggregatorWeb.CollectionLive.ImportFormComponent do
  @moduledoc false
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.DataFrame
  alias DataAggregator.Records.Import
  alias Phoenix.LiveView.UploadEntry

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:file,
       max_entries: 1,
       accept: DataFrame.supported_exts(),
       max_file_size: 200 * 1024 * 1024,
       auto_upload: true
     )
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal_header
        modal_id="import-modal"
        icon={@icon}
        title={@title}
        description={~t"Select a file containing your Records"m}
      />

      <.simple_form
        for={@form}
        id="import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
        <section
          phx-drop-target={@uploads.file.ref}
          class="border-gray-900/25 mt-2 flex flex-col rounded-md border border-dashed px-6 py-10 dark:border-white/25"
        >
          <div class="flex justify-center">
            <div class="text-center">
              <.icon
                name="hero-photo-mini"
                class="dark:text-gray-500 w-12 h-12 mx-auto text-gray-300"
              />
              <div class="mt-4 flex text-sm leading-6 text-gray-600 dark:text-gray-400">
                <label
                  for={@uploads.file.ref}
                  class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500 dark:bg-gray-900 dark:text-white dark:focus-within:ring-offset-gray-900"
                >
                  <span><%= ~t"Choose a file"m %></span>
                  <.live_file_input upload={@uploads.file} class="sr-only" />
                </label>
                <p class="pl-1"><%= ~t"or drag and drop"m %></p>
              </div>
              <p class="text-xs leading-5 text-gray-600 dark:text-gray-400">
                <%= pretty_accept_list(@uploads.file.accept) %>
                <%= pretty_max_file_size(@uploads.file.max_file_size) %>
              </p>
            </div>
          </div>

          <div class="mt-4 space-y-2 text-gray-600 dark:text-white">
            <%!-- render each file entry --%>
            <article :for={entry <- @uploads.file.entries}>
              <span class="text-sm"><%= entry.client_name %></span>

              <div class="flex items-center space-x-4">
                <.progress value={entry.progress} />
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-target={@myself}
                  phx-value-ref={entry.ref}
                  aria-label="cancel"
                  class="flex h-full items-center"
                >
                  <.icon name="hero-x-mark-mini" class="text-gray-600" />
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
            label={~t"Upload file"m}
          />
          <.button
            color="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
            label={~t"Cancel"m}
            phx-click={JS.exec("data-cancel", to: "#import-modal")}
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

    imports =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        case handle_upload(collection, path, entry) do
          {:ok, import} ->
            {:ok, import}

          {:error, error} ->
            Logger.error(error)
            {:postpone, "Could not create import file"}
        end
      end)

    import = Enum.at(imports, 0)

    notify_parent({:imported, import})

    {
      :noreply,
      socket
      |> handle_flash(import)
      |> push_patch(to: socket.assigns.patch)
    }
  end

  defp handle_flash(socket, import) when is_nil(import) == false do
    # |> put_flash(:info, "File successfully uploaded")
    socket
  end

  defp handle_flash(socket, import) when is_nil(import) do
    put_flash(socket, :error, "File upload failed")
  end

  def pretty_accept_list(term) when is_binary(term) do
    term
    |> String.split(",")
    |> Enum.map_join(", ", &(&1 |> String.replace(~r/^\./, "") |> String.upcase()))
  end

  def pretty_accept_list(_), do: nil

  def pretty_max_file_size(max_file_size) when is_number(max_file_size) do
    max_file_size =
      DataAggregatorWeb.Helpers.format_bytes(max_file_size)

    mgettext("up to %{max_file_size}", max_file_size: max_file_size)
  end

  def pretty_max_file_size(_), do: nil

  defp handle_upload(collection, path, %UploadEntry{} = entry) do
    Import.create_from_path(collection, path, %{filename: entry.client_name})
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
