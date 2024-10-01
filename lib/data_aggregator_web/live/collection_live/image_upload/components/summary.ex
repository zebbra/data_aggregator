defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Components.Summary do
  @moduledoc """
  This module contains components for the collectiion > image upload live view.
  """

  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.ImageUpload.Components
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

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
            <.file_info attachment={@image_upload.attachment} />
            <.attachment_download_badge attachment={@image_upload.attachment} />
          </:item>
          <:item title={~t"Invalid files count"}>
            <%= invalid_file_infos(@image_upload.invalid_file_infos) %>
          </:item>
        </.list>
      </div>

      <.section_heading text={~t"Mapping"m} class="px-6 lg:px-6 text-left" />

      <div class="h-full overflow-y-auto overflow-x-hidden px-6 py-1">
        <.list dense>
          <:item title={~t"Chosen Identifier"m}>
            <%= @image_upload.mapping_identifier %>
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
          <%= ~t"Run Mapping"m %>
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
    case ImageUpload.enqueue_mapping(socket.assigns.image_upload) do
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

  defp invalid_file_infos(nil), do: 0

  defp invalid_file_infos(infos) do
    {file_size_infos, file_extension_infos} =
      Enum.split_with(infos, &(&1["reason"] == "file_size"))

    assigns = %{file_size_infos: file_size_infos, file_extension_infos: file_extension_infos}

    ~H"""
    <div :if={length(@file_size_infos) > 0}>
      <.section_heading
        :if={length(@file_size_infos) > 0}
        text={~t"File size limit exceeded"m}
        size="sm"
        class="text-red-500"
      />
      <%= length(@file_size_infos) %>
    </div>
    <div :if={length(@file_extension_infos) > 0}>
      <.section_heading
        :if={length(@file_extension_infos) > 0}
        text={~t"Invalid file extension"m}
        size="sm"
        class="text-red-500"
      />
      <%= length(@file_extension_infos) %>
    </div>
    """
  end
end
