defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Components.Summary do
  @moduledoc """
  This module contains components for the collectiion > image upload live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.ImageUpload.Components
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.ImageUpload

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id} title_class="!-mr-4 w-full">
        <.stepper
          current={current_step(@action)}
          links={[
            nil,
            build_path(~p"/collections/#{@collection}/image_uploads/#{@image_upload}/edit", @meta),
            nil
          ]}
        />
        <.section_heading
          text={~t"Summary"m}
          description={~t"Please review the image upload summary."m}
          class="mt-4"
        >
          <:actions>
            <div class="flex items-center gap-x-2">
              <span class="text-sm max-sm:hidden"><%= ~t"State:"m %></span>
              <.image_upload_state_badge image_upload={@image_upload} />
            </div>
          </:actions>
        </.section_heading>
      </.modal_header>

      <div class="h-full overflow-y-auto overflow-x-hidden px-6 py-1">
        <.list dense>
          <:item title={~t"File"m}>
            <.file_info attachment={@image_upload.attachment} show_rows={false} />
            <.attachment_download_badge attachment={@image_upload.attachment} />
          </:item>
          <:item title={~t"Created at"m}>
            <%= format_datetime(@image_upload.inserted_at) %>
          </:item>
          <:item title={~t"Invalid files"}>
            <%= invalid_file_infos(@image_upload.invalid_file_infos) %>
          </:item>
        </.list>

        <.section_heading text={~t"Mapping"m} size="md" class="pt-4" />
        <.list dense>
          <:item title={~t"Chosen Identifier"m}>
            <%= Schema.dwc_field_from_prefixed_attribute_name(@image_upload.mapping_identifier) %>
          </:item>
        </.list>
      </div>

      <.modal_footer id={@id}>
        <button
          disabled={@busy}
          type="button"
          class="btn btn-primary"
          phx-click="mapping:run"
          phx-value-id={@image_upload.id}
          phx-target={@myself}
        >
          <%= run_mapping_text(@image_upload) %>
        </button>
        <.link
          patch={
            build_path(~p"/collections/#{@collection}/image_uploads/#{@image_upload}/edit", @meta)
          }
          type="button"
          class="btn btn-ghost"
        >
          <%= ~t"Back"m %>
        </.link>
      </.modal_footer>
    </div>
    """
  end

  @impl true
  def handle_event("mapping:run", _params, socket) do
    actor = get_actor(socket)

    case ImageUpload.enqueue_mapping(socket.assigns.image_upload, actor: actor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, ~t"Mapping started in background"m)
         |> close_and_redirect()}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, ~t"Not able to enqueue mapping"m)
         |> close_and_redirect()}
    end
  end

  defp close_and_redirect(socket) do
    socket
    |> push_event("submit:close", %{})
    |> push_patch(
      to:
        build_path(
          ~p"/collections/#{socket.assigns.collection}/image_uploads",
          socket.assigns.meta
        )
    )
  end

  defp run_mapping_text(%ImageUpload{state: :mapped}), do: ~t"Re-run Mapping"m
  defp run_mapping_text(_), do: ~t"Run Mapping"m

  defp invalid_file_infos(nil), do: 0
  defp invalid_file_infos([]), do: 0

  defp invalid_file_infos(infos) do
    {file_size_infos, file_extension_infos} =
      Enum.split_with(infos, &(&1["reason"] == "file_size"))

    assigns = %{file_size_infos: file_size_infos, file_extension_infos: file_extension_infos}

    ~H"""
    <div :if={length(@file_size_infos) > 0}>
      <%= "#{length(@file_size_infos)} #{files_plural(length(@file_size_infos))} exeeded file size limit" %>
    </div>
    <div :if={length(@file_extension_infos) > 0}>
      <%= "#{length(@file_extension_infos)} #{files_plural(length(@file_extension_infos))}  with invalid file extension" %>
    </div>
    """
  end

  defp files_plural(1), do: ~t"file"m
  defp files_plural(_), do: ~t"files"m
end
