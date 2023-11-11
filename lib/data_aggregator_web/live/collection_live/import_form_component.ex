defmodule DataAggregatorWeb.CollectionLive.ImportFormComponent do
  use DataAggregatorWeb, :live_component

  alias AshPhoenix.Form
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Import

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:file,
       max_entries: 1,
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
        id="import-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!-- use phx-drop-target with the upload ref to enable file drag and drop --%>
        <section
          phx-drop-target={@uploads.file.ref}
          class="border-gray-900/25 dark:border-white/25 flex flex-col px-6 py-10 mt-2 border border-dashed rounded-md"
        >
          <div class="flex justify-center">
            <div class="text-center">
              <.icon
                name="hero-photo-mini"
                class="dark:text-gray-500 w-12 h-12 mx-auto text-gray-300"
              />
              <div class="dark:text-gray-400 flex mt-4 text-sm leading-6 text-gray-600">
                <label
                  for={@uploads.file.ref}
                  class="dark:bg-gray-900 dark:text-white focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 dark:focus-within:ring-offset-gray-900 hover:text-indigo-500 relative font-semibold text-indigo-600 bg-white rounded-md cursor-pointer"
                >
                  <span><%= ~t"Choose a file"m %></span>
                  <.live_file_input upload={@uploads.file} class="sr-only" />
                </label>
                <p class="pl-1"><%= ~t"or drag and drop"m %></p>
              </div>
              <p class="dark:text-gray-400 text-xs leading-5 text-gray-600">
                <%= pretty_accept_list(@uploads.file.accept) %>
                <%= pretty_max_file_size(@uploads.file.max_file_size) %>
              </p>
            </div>
          </div>

          <div class="dark:text-white mt-4 space-y-2 text-gray-600">
            <%!-- render each file entry --%>
            <article :for={entry <- @uploads.file.entries}>
              <span class="text-sm"><%= entry.client_name %></span>

              <div class="flex space-x-4">
                <div class="dark:bg-gray-700 w-full h-2 mt-2 bg-gray-200 rounded-full">
                  <div
                    class="dark:bg-indigo-500 h-2 bg-indigo-600 rounded-full"
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
            phx-disable-with={~t"Uploading..."m}
          >
            <%= ~t"Upload file"m %>
          </.button>
          <.button
            variant="secondary"
            class="sm:mt-0 sm:w-auto inline-flex justify-center w-full mt-3"
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

  attr :icon, :string, default: nil
  attr :title, :string, required: true

  defp form_header(assigns) do
    ~H"""
    <div class="sm:flex sm:items-start">
      <div
        :if={@icon}
        class="sm:mx-0 sm:h-10 sm:w-10 flex items-center justify-center flex-shrink-0 w-12 h-12 mx-auto bg-indigo-100 rounded-full"
      >
        <.icon name={@icon} class="w-6 h-6 text-indigo-600" />
      </div>
      <div class={["mt-3 text-center sm:mt-0 sm:text-left", @icon && "sm:ml-4"]}>
        <.dialog_title
          id="import-modal__title"
          class="dark:text-white text-base font-semibold leading-6 text-gray-900"
        >
          <%= @title %>
        </.dialog_title>
        <.dialog_description
          id="import-modal__description"
          class="dark:text-gray-400 mt-2 text-sm text-gray-500"
        >
          <%= ~t"Select a file containing your Records"m %>
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
      consume_uploaded_entries(socket, :file, fn %{path: path}, _entry ->
        case handle_upload(collection, path) do
          {:ok, import} ->
            {:ok, import}

          {:error, _} ->
            {:error, "Could not create import file"}
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
    socket |> put_flash(:error, "File upload failed")
  end

  def pretty_accept_list(term) when is_binary(term) do
    term
    |> String.split(",")
    |> Enum.map_join(", ", &(String.replace(&1, ~r/^\./, "") |> String.upcase()))
  end

  def pretty_accept_list(_), do: nil

  def pretty_max_file_size(max_file_size) when is_number(max_file_size) do
    max_file_size =
      max_file_size
      |> DataAggregatorWeb.Helpers.format_bytes()

    mgettext("up to %{max_file_size}", max_file_size: max_file_size)
  end

  def pretty_max_file_size(_), do: nil

  defp handle_upload(collection, path) do
    Import.create_from_path(collection, path)
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
