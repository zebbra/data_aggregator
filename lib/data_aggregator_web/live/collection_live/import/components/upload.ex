defmodule DataAggregatorWeb.CollectionLive.Import.Components.Upload do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

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
     |> assign(error_message: nil)
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
    <div class="contents">
      <.modal_header id={@id}>
        <.stepper current={current_step(@action)} steps={3} />
        <.section_heading
          text={~t"Import records"m}
          description={~t"Please provide your collection file holding your records."m}
          class="mt-4"
        />
      </.modal_header>

      <.simple_form
        for={@form}
        id="import_upload_form"
        class="contents"
        phx-target={@myself}
        phx-change="upload:validate"
        phx-submit="upload:save"
      >
        <div class="h-full overflow-y-auto px-6 py-8">
          <.fieldset>
            <.fieldgroup>
              <div
                :if={@error_message}
                class="collapse text-error-content border-error/20 bg-error/10 border"
              >
                <input type="checkbox" />
                <div class="collapse-title text-error pe-4 flex items-center gap-x-2 text-sm">
                  <div class="flex min-w-0 flex-1 items-center gap-x-2">
                    <.icon name="hero-exclamation-triangle" />
                    <span><%= ~t"An error has occurred"m %></span>
                  </div>
                  <%= ~t"Show more"m %>
                </div>
                <div class="collapse-content">
                  <div class="text-error text-sm/6">
                    <%= @error_message %>
                  </div>
                </div>
              </div>
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
                        <span><%= ~t"Choose a file"m %></span>
                        <.live_file_input upload={@uploads.file} class="sr-only" />
                      </label>
                      <p class="pl-1"><%= ~t"or drag and drop"m %></p>
                    </div>
                    <p class="text-xs/5 text-base-content/60">
                      <%= pretty_accept_list(@uploads.file.accept) %>
                    </p>
                    <p class="text-xs/5 text-base-content/60">
                      <%= pretty_max_file_size(@uploads.file.max_file_size) %>
                    </p>
                  </div>
                </div>

                <div class="text-base-content mt-4 space-y-2">
                  <article :for={entry <- @uploads.file.entries}>
                    <span class="text-sm"><%= entry.client_name %></span>

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
                        <p class="text-sm text-red-500"><%= error_to_string(err) %></p>
                      <% end %>
                    </div>
                  </article>
                </div>
              </section>
            </.fieldgroup>
          </.fieldset>
        </div>

        <:actions modal>
          <button
            type="submit"
            class={["btn btn-primary", Enum.any?(@uploads.file.errors) && "btn-disabled"]}
          >
            <%= ~t"Upload file"m %>
          </button>
          <button type="button" class="btn btn-ghost" onclick="import_modal.close()">
            <%= ~t"Cancel"m %>
          </button>
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
  def handle_event("upload:validate", _params, socket) do
    {:noreply, check_for_errors(socket)}
  end

  @impl true
  def handle_event("upload:cancel", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:file, ref) |> validate_max_entries()}
  end

  @impl true
  def handle_event("upload:save", _params, socket) do
    if Enum.empty?(socket.assigns.uploads.file.entries) do
      {:noreply, assign(socket, :error_message, error_to_string(:required))}
    else
      collection = socket.assigns.collection
      results = consume(socket, collection)

      handle_upload_result(socket, results, collection)
    end
  end

  defp handle_upload_result(socket, results, collection) do
    case Enum.at(results, 0) do
      {:error, error} ->
        error_message = "File upload failed with error #{inspect(error)}"

        {
          :noreply,
          socket
          |> assign(error_message: error_message)
          |> push_patch(to: ~p"/collections/#{collection}/imports/new")
        }

      %Import{} = import ->
        {
          :noreply,
          socket
          |> handle_flash(import)
          |> push_patch(
            to:
              build_path(
                ~p"/collections/#{collection}/imports/#{import}/edit",
                socket.assigns.meta
              )
          )
        }

      _ ->
        {
          :noreply,
          socket
          |> handle_flash(nil)
          |> push_patch(to: build_path(~p"/collections/#{collection}/imports", meta: socket.assigns.meta))
        }
    end
  end

  defp consume(socket, collection) do
    consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
      case handle_upload(collection, path, entry) do
        {:ok, import} ->
          {:ok, import}

        {:error, error} ->
          Logger.error(error)
          handle_upload_error(error)
      end
    end)
  end

  defp handle_upload_error(error) do
    case error do
      %Ash.Error.Invalid{} = error ->
        {:postpone, {:error, Enum.map_join(error.errors, ", ", & &1.message)}}

      error ->
        {:postpone, {:error, "Could not create import file: #{inspect(error)}"}}
    end
  end

  defp handle_upload(collection, path, %UploadEntry{} = entry) do
    Import.create_from_path(collection, path, %{filename: entry.client_name})
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

  # There seems to be a bug in the live view upload component as the entry
  # ref does not match the upload ref. Thus we need validate max_entries
  # manually.
  defp validate_max_entries(socket) do
    if has_too_many_files?(socket) do
      assign(socket, :error_message, error_to_string(:too_many_files))
    else
      assign(socket, :error_message, nil)
    end
  end

  defp check_for_errors(socket) do
    cond do
      has_too_many_files?(socket) ->
        assign(socket, :error_message, error_to_string(:too_many_files))

      other_error_message?(socket) ->
        assign(socket, :error_message, socket.assigns.error_message)

      true ->
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

  defp error_to_string(:required), do: ~t"Please select a file"m
  defp error_to_string(:too_large), do: ~t"Too large"m
  defp error_to_string(:too_many_files), do: ~t"You have selected too many files"m
  defp error_to_string(:not_accepted), do: ~t"You have selected an unacceptable file type"m
  defp error_to_string(_), do: ~t"An error has occurred"m
end
