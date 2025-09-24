defmodule DataAggregatorWeb.AdministrationLive.ValidationResponse.Components.Upload do
  @moduledoc """
  Upload component for the validation response live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]

  alias AshPhoenix.Form
  alias DataAggregator.Records.ValidationResponse
  alias Phoenix.LiveView.UploadEntry

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(error_message: nil)
     |> assign(:uploaded_files, [])
     |> assign(:uploading, false)
     |> assign(:type, :validated)
     |> allow_upload(:file,
       max_entries: 1,
       accept: ~w(.zip),
       max_file_size: 800 * 1024 * 1024,
       auto_upload: true,
       progress: &handle_progress/3
     )
     |> assign_form()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id}>
        <.stepper current={1} steps={2} />
        <.section_heading
          text={~t"Import validation layer data"m}
          description={
            ~t"Please choose whether to import a file containing successfully validated records or a file containing non-validated records that have been refused by the Swiss species data centers."m
          }
          class="mt-4"
        />
      </.modal_header>
      <.simple_form
        for={@form}
        id="validation_response_upload_form"
        class="contents"
        phx-target={@myself}
        phx-change="upload:validate"
        phx-submit="upload:save"
      >
        <div class="h-full overflow-y-auto px-6 py-8">
          <.fieldset>
            <.fieldgroup>
              <.collapsible_notification
                :if={@error_message}
                title={~t"An error has occurred"m}
                color="red"
              >
                <:action>
                  {~t"Show more"m}
                </:action>
                {@error_message}
              </.collapsible_notification>
              <.field
                type="radio"
                field={@form[:type]}
                id="type_option_1"
                label={~t"Validated"m}
                description={~t"Validated records"m}
                checked={@form[:type].value == :validated}
                value={:validated}
              />
              <.field
                type="radio"
                field={@form[:type]}
                id="type_option_2"
                label={~t"Not Validated"m}
                description={~t"Not validated records"m}
                checked={@form[:type].value == :not_validated}
                value={:not_validated}
              />
              <section
                phx-drop-target={@uploads.file.ref}
                class="border-black-white/25 flex flex-col rounded-lg border border-dashed px-6 py-10"
              >
                <div class="flex justify-center">
                  <div class="text-center">
                    <.icon name="hero-photo-mini" class="text-base-content/25 size-12 mx-auto" />
                    <div class="text-sm/6 text-base-content mt-4 flex justify-center">
                      <label
                        for={@uploads.file.ref}
                        class="link link-primary link-hover rounded-md px-1 font-semibold focus-within:ring-primary focus-within:ring-2"
                      >
                        <span>{~t"Choose a file"m}</span>
                        <.live_file_input upload={@uploads.file} class="sr-only" />
                      </label>
                      <p class="pl-1">{~t"or drag and drop"m}</p>
                    </div>
                    <p class="text-xs/5 text-base-content/60">
                      {pretty_accept_list(@uploads.file.accept)}
                    </p>
                    <p class="text-xs/5 text-base-content/60">
                      {pretty_max_file_size(@uploads.file.max_file_size)}
                    </p>
                  </div>
                </div>
                <div class="text-base-content mt-4 space-y-2">
                  <article :for={entry <- @uploads.file.entries}>
                    <span class="text-sm">{entry.client_name}</span>

                    <div class="flex items-center space-x-4">
                      <.progress value={entry.progress} class="progress-primary" />
                      <button
                        type="button"
                        phx-click="upload:cancel"
                        phx-target={@myself}
                        phx-value-ref={entry.ref}
                        class="btn btn-sm btn-circle btn-ghost"
                        aria-label={~t"close"m}
                      >
                        <.icon name="hero-x-mark-mini" class="text-base-content/75" />
                      </button>
                    </div>

                    <div>
                      <%= for err <- upload_errors(@uploads.file, entry) do %>
                        <p class="text-sm text-red-500">{error_to_string(err)}</p>
                      <% end %>
                    </div>
                  </article>
                </div>
              </section>

              <div class="flex">
                <div class="mr-4 flex-shrink-0">
                  <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
                </div>
                <p class="text-sm">
                  {~t"Please make sure that the provided file has been verified and only contains correct and valid input. DAGI will only run a very simple verification check of the file"m}
                </p>
              </div>
            </.fieldgroup>
          </.fieldset>
        </div>

        <:actions modal>
          <button
            type="submit"
            class="btn btn-primary"
            disabled={
              @uploading || Enum.any?(@uploads.file.errors) || Enum.empty?(@uploads.file.entries)
            }
            phx-disable-with={~t"Save..."m}
          >
            {if @uploading, do: ~t"Uploading..."m, else: ~t"Next"m}
          </button>
          <button type="button" class="btn btn-ghost" onclick="validation_response_modal.close()">
            {~t"Cancel"m}
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("upload:validate", %{"validation_response" => %{"type" => type}}, socket) do
    form = Form.validate(socket.assigns.form, %{type: String.to_atom(type)})

    socket =
      socket
      |> check_for_errors()
      |> assign(:form, form)

    {:noreply, socket}
  end

  @impl true
  def handle_event("upload:cancel", %{"ref" => ref}, socket) do
    {:noreply,
     socket
     |> cancel_upload(:file, ref)
     |> validate_max_entries()
     |> assign(:uploading, false)}
  end

  @impl true
  def handle_event("upload:save", _params, socket) do
    if Enum.empty?(socket.assigns.uploads.file.entries) do
      {:noreply, assign(socket, :error_message, error_to_string(:required))}
    else
      results = consume(socket)

      handle_upload_result(socket, results)
    end
  end

  defp handle_upload_result(socket, results) do
    case Enum.at(results, 0) do
      {:error, error} ->
        error_message = "File upload failed with error #{inspect(error)}"

        {
          :noreply,
          socket
          |> assign(error_message: error_message)
          |> push_patch(to: ~p"/administration/validation_responses/new")
        }

      %ValidationResponse{} = validation_response ->
        {
          :noreply,
          socket
          |> handle_flash(validation_response)
          |> push_patch(to: ~p"/administration/validation_responses/#{validation_response.id}/summary")
        }

      _ ->
        {
          :noreply,
          socket
          |> handle_flash(nil)
          |> push_patch(to: ~p"/administration/validation_responses")
        }
    end
  end

  defp consume(socket) do
    actor = get_actor(socket)

    consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
      case handle_upload(path, entry, actor, socket.assigns.form.params.type) do
        {:ok, validation_response} ->
          {:ok, validation_response}

        {:error, error} ->
          Logger.warning(error)
          handle_upload_error(error)
      end
    end)
  end

  defp handle_upload_error(error) do
    case error do
      %Ash.Error.Invalid{} = error ->
        {:postpone, {:error, Enum.map_join(error.errors, ", ", & &1.message)}}

      error ->
        {:postpone, {:error, "Could not create ValidationResponse file: #{inspect(error)}"}}
    end
  end

  defp handle_upload(path, %UploadEntry{} = entry, actor, type) do
    ValidationResponse.create_from_path(
      path,
      entry.client_name,
      %{created_by_id: actor.id, type: type}
    )
  end

  defp check_for_errors(socket) do
    cond do
      has_too_many_files?(socket) ->
        assign(socket, :error_message, error_to_string(:too_many_files))

      other_error_message?(socket) ->
        assign(socket, :error_message, socket.assigns.error_message)

      true ->
        socket
        |> assign(:error_message, nil)
        |> assign(:uploading, true)
    end
  end

  defp validate_max_entries(socket) do
    if has_too_many_files?(socket) do
      assign(socket, :error_message, error_to_string(:too_many_files))
    else
      assign(socket, :error_message, nil)
    end
  end

  defp other_error_message?(socket), do: socket.assigns.error_message != nil

  defp has_too_many_files?(socket) do
    Enum.any?(socket.assigns.uploads.file.errors, fn
      {_id, :too_many_files} -> true
      _ -> false
    end)
  end

  defp handle_progress(:file, entry, socket) do
    if entry.done? do
      {:noreply, assign(socket, uploading: false)}
    else
      {:noreply, socket}
    end
  end

  defp assign_form(%{assigns: assigns} = socket) do
    assign(socket, :form, build_form(assigns))
  end

  defp build_form(%{action: :new}) do
    ValidationResponse
    |> Form.for_create(
      :create,
      domain: DataAggregator.Records,
      as: "validation_response"
    )
    |> to_form()
  end

  defp handle_flash(socket, import) when is_nil(import) == false do
    # |> put_flash(:info, ~t"File successfully uploaded"m)
    socket
  end

  defp handle_flash(socket, import) when is_nil(import) do
    put_flash(socket, :error, ~t"File upload failed"m)
  end

  defp pretty_accept_list(term) when is_binary(term) do
    term
    |> String.split(",")
    |> Enum.map_join(", ", &(&1 |> String.replace(~r/^\./, "") |> String.upcase()))
  end

  defp pretty_accept_list(_), do: nil

  defp pretty_max_file_size(max_file_size) when is_number(max_file_size) do
    max_file_size =
      DataAggregatorWeb.Helpers.format_bytes(max_file_size)

    mgettext("up to %{max_file_size}", max_file_size: max_file_size)
  end

  defp pretty_max_file_size(_), do: nil

  defp error_to_string(:required), do: ~t"Please select a file"m
  defp error_to_string(:too_large), do: ~t"Too large"m
  defp error_to_string(:too_many_files), do: ~t"You have selected too many files"m
  defp error_to_string(:not_accepted), do: ~t"You have selected an unacceptable file type"m
  defp error_to_string(_), do: ~t"An error has occurred"m
end
