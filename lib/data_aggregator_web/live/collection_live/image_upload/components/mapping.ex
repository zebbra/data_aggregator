defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Components.Mapping do
  @moduledoc """
  Component for selecting the mapping identifier for the collection image upload.
  """
  use DataAggregatorWeb, :live_component

  import DataAggregatorWeb.CollectionLive.Collection.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

  alias DataAggregator.Records.ImageUpload

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_mapping_identifier_options()
      |> assign_form()

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.modal_header id={@id}>
        <.stepper
          current={current_step(@action)}
          links={valid_links(@collection, @image_upload, @meta)}
        />
        <.section_heading
          text={~t"Choose Identifier"m}
          description={~t"Please map your images to existing records."m}
          class="mt-4"
        >
        </.section_heading>
      </.modal_header>

      <.simple_form
        id="image_mapping_identifier_form"
        for={@form}
        phx-target={@myself}
        phx-change="mapping:validate"
        phx-submit="mapping:save"
        class="contents"
      >
        <div class="h-full overflow-y-auto px-6 py-8">
          <.fieldset>
            <.fieldgroup>
              <div class="flex">
                <div class="mr-4 flex-shrink-0">
                  <.icon name="hero-information-circle-mini" class="size-6 text-primary" />
                </div>
                <div>
                  <p class="text-sm">
                    {~t"The mapping identifier links image filenames to records by matching the part before an underscore (or the file extension if no underscore exists) with a chosen attribute, like catalogNumber, materialEntitiyId or occurenceId."}
                    <br />
                    <br />
                    {~t"For example: 'catalogNumber001_01.jpg' maps to a record where its catalogNumber is 'catalogNumber001'."}
                  </p>
                </div>
              </div>
              <.field
                type="combobox"
                dropup
                field={@form[:mapping_identifier]}
                label={~t"Mapping Identifier"m}
                options={@mapping_identifier_options}
                placeholder={~t"Select mapping identifier"m}
                data-portal="image_upload_modal"
              />
            </.fieldgroup>
          </.fieldset>
        </div>

        <:actions modal>
          <button
            type="submit"
            class="btn btn-primary"
            disabled={@image_upload.state in [:extraction_queued, :extracting, :mapping]}
          >
            {~t"Save"m}
            {~t"Update mapping"m}
          </button>
          <button type="button" class="btn btn-ghost" onclick="image_upload_modal.close()">
            {~t"Cancel"m}
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("mapping:validate", %{"image_upload" => params}, socket) do
    %{form: form} = socket.assigns

    form = AshPhoenix.Form.validate(form, params)

    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("mapping:save", %{"image_upload" => params}, socket) do
    %{form: form, collection: collection, meta: meta} = socket.assigns

    socket =
      case AshPhoenix.Form.submit(form, params: params) do
        {:ok, image_upload} ->
          push_patch(socket,
            to:
              build_path(
                ~p"/datasets/#{collection}/image_uploads/#{image_upload}/summary",
                meta
              )
          )

        {:error, form} ->
          assign(socket, :form, form)
      end

    {:noreply, socket}
  end

  defp assign_form(socket) do
    %{current_user: actor, image_upload: image_upload} = socket.assigns

    assign(socket, :form, build_form(image_upload, actor))
  end

  defp build_form(image_upload, actor) do
    image_upload
    |> AshPhoenix.Form.for_update(:update_mapping_identifier,
      domain: DataAggregator.Records,
      as: "image_upload",
      actor: actor
    )
    |> to_form()
  end

  defp assign_mapping_identifier_options(socket) do
    options = ImageUpload.Helpers.mapping_identifier_options()

    assign(socket, :mapping_identifier_options, options)
  end

  defp valid_links(collection, image_upload, meta) do
    summary =
      build_path(~p"/datasets/#{collection}/image_uploads/#{image_upload}/summary", meta)

    [nil, nil, summary]
  end
end
