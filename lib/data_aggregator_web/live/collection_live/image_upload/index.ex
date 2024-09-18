defmodule DataAggregatorWeb.CollectionLive.ImageUpload.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.CollectionLive.Components.Header, only: [collection_header: 1]
  import DataAggregatorWeb.CollectionLive.Helpers, only: [get_collection_light: 2]
  import DataAggregatorWeb.CollectionLive.ImageUpload.Helpers
  import DataAggregatorWeb.Layouts.Secondary, only: [page: 1]

  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.ImageUpload

  @load load()

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    collection = get_collection_light(id, get_actor(socket))

    socket =
      socket
      |> assign(:collection, collection)
      |> assign(:selected_image_upload, nil)
      |> assign(:busy, collection.busy)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    case list_image_uploads(params, get_actor(socket)) do
      {:ok, {results, meta}} ->
        socket
        |> assign(meta: meta)
        |> stream(:results, results, reset: true)
        |> apply_action(socket.assigns.live_action, params)
        |> noreply()

      {:error, _meta} ->
        {:noreply, push_navigate(socket, to: ~p"/collections/#{id}/image_uploads")}
    end

    # socket |> apply_action(socket.assigns.live_action, params) |> assign(meta: %{}) |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="collections" current_user={@current_user}>
      <.collection_header
        collection={@collection}
        current={:image_upload}
        current_user={@current_user}
        disabled={@busy}
      />
      <.secondary_navigation class="sticky top-[calc(4rem-1px)]">
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/records"}
          label={~t"Records"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/imports"}
          label={~t"Imports"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/exports"}
          label={~t"Exports"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/publications"}
          label={~t"Publications and Approvals"m}
        />
        <.secondary_navigation_item
          href={~p"/collections/#{@collection}/image_uploads"}
          label={~t"Image Upload"m}
          active
        />
      </.secondary_navigation>

      <.table
        opts={[
          no_results_content:
            no_results_content(%{collection: @collection, current_user: @current_user})
        ]}
        path={~p"/collections/#{@collection}/image_uploads"}
        items={@streams.results}
        meta={@meta}
        row_click={
          fn {_id, image_upload} ->
            JS.push("image_upload:select", value: %{id: image_upload.id})
          end
        }
      >
        <%!-- <:col :let={{_id, import}} field={:state} label={~t"State"m}>
          <.import_state_badge import={import} />
        </:col> --%>
        <:col :let={{_id, image_upload}} label={~t"File"m}>
          <.file_info attachment={image_upload.attachment} files_count={image_upload.images_count} />
        </:col>
        <:col :let={{_id, image_upload}} label={~t"Size"m}>
          <.attachment_download_badge attachment={image_upload.attachment} />
        </:col>
        <:col :let={{_id, image_upload}} field={:started_at} label={~t"Started at"m}>
          <%= format_datetime(image_upload.started_at, format: :short) %>
          <%!-- <div :if={image_upload.duration} class="text-base-content/60 text-xs">
            <%= image_upload.duration %>
          </div> --%>
        </:col>

        <:action
          :let={{_id, image_upload}}
          :if={Collection.can_set_importing?(@current_user, @collection)}
          tbody_td_attrs={[class: "pr-6 lg:pr-8 whitespace-nowrap text-right w-0"]}
          col_class="bg-base-300/10 border-l border-black-white/5"
          label={~t"Actions"m}
        >
          <%!-- <div
            :if={invalid?(image_upload)}
            class="link tooltip link-hover btn btn-sm btn-circle btn-ghost inline-flex"
            data-tip={~t"Mapping is invalid"m}
          >
            <.icon name="hero-exclamation-circle-mini" class="size-5 text-base-content/75" />
          </div> --%>

          <div class="border-black-white/10 mr-4 inline-flex border-r pr-4">
            <.table_action_button
              patch={
                build_path(~p"/collections/#{@collection}/image_uploads/#{image_upload}/edit", @meta)
              }
              data-tip={~t"Edit"m}
              disabled={@busy}
              icon="hero-pencil-square-mini"
            />
          </div>

          <.table_action_button
            type="button"
            phx-click={JS.push("image_upload:delete", value: %{id: image_upload.id})}
            data-tip={~t"Delete"m}
            data-confirm={~t"Are you sure?"m}
            data-confirm_id="confirm_image_upload_alert"
            disabled={@busy}
            icon="hero-trash-mini"
          />
        </:action>
      </.table>
      <.pagination meta={@meta} path={~p"/collections/#{@collection}/image_uploads"} />

      <:secondary></:secondary>
      <:portal>
        <.modal
          id="image-upload-modal"
          class="no-scrollbar"
          show={@live_action in [:new, :edit, :summary]}
          size="2xl"
          responsive
          backdrop={false}
          on_cancel={JS.patch(build_path(~p"/collections/#{@collection}/image_uploads", nil))}
          overflow="manual"
        >
          <.live_component
            :if={@live_action in [:new, :edit, :summary]}
            module={DataAggregatorWeb.CollectionLive.ImageUpload.FormComponent}
            id={@image_upload.id || :new}
            action={@live_action}
            image_upload={@image_upload}
            collection={@collection}
            meta={@meta}
            busy={@busy}
            current_user={@current_user}
          />
        </.modal>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("image_upload:delete", %{"id" => id}, socket) do
    actor = get_actor(socket)
    image_upload = ImageUpload.get_by_id!(id, actor: actor)
    :ok = ImageUpload.destroy(image_upload, actor: actor)

    {:noreply,
     socket
     |> put_flash(:info, ~t"Image Upload deleted successfully"m)
     |> stream_delete(:results, image_upload)}
  end

  @impl true
  def handle_event("image_upload:select", %{"id" => nil}, socket) do
    socket = assign(socket, selected_iimage_upload: nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("image_upload:select", %{"id" => id}, socket) do
    image_upload = ImageUpload.get_by_id(id, actor: get_actor(socket))

    {:noreply, assign(socket, selected_image_upload: image_upload)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Image Upload"m)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, ~t"New Image Upload"m)
    |> assign(:image_upload, %ImageUpload{})
  end

  defp apply_action(socket, :edit, %{"image_upload_id" => id}) do
    image_upload = ImageUpload.get_by_id!(id, actor: get_actor(socket))

    socket
    |> assign(:page_title, ~t"Edit Image Upload"m)
    |> assign(:image_upload, image_upload)
  end

  defp list_image_uploads(params, actor, opts \\ [load: @load, action: :by_collection]) do
    opts = Keyword.put_new(opts, :actor, actor)
    AshPagify.validate_and_run(ImageUpload, params, opts, params["id"])
  end

  defp no_results_content(assigns) do
    ~H"""
    <.empty_state
      title={~t"No image uploads"m}
      description={~t"Get started by uploading a new zip file."m}
      label={~t"Upload Images"m}
      icon="hero-arrow-up-tray"
      href={~p"/collections/#{@collection}/image_uploads/new"}
    />
    """
  end
end
