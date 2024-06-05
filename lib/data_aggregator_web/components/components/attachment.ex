defmodule DataAggregatorWeb.Components.Attachment do
  @moduledoc """
  This module contains components for the attachment.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Components.Icon, only: [icon: 1]
  import DataAggregatorWeb.Gettext
  import DataAggregatorWeb.Helpers, only: [format_bytes: 1, format_number: 1]

  alias DataAggregator.Files.Attachment

  @doc """
  Renders a download badge for an attachment.
  """
  attr :attachment, Attachment, required: true, doc: "the attachment to display"
  attr :class, :string, default: nil, doc: "additional classes to apply to the badge"

  def attachment_download_badge(assigns) do
    ~H"""
    <.link
      href={@attachment.url}
      class={[
        "inline-flex items-center rounded-md bg-blue-100 px-1.5 py-0.5 text-xs font-medium text-blue-700 opacity-75 hover:opacity-100 gap-x-1",
        @class
      ]}
      tabindex="-1"
      phx-click=""
    >
      <.icon name="hero-arrow-down-tray-mini" class="size-3 shrink-0" />
      <span class="whitespace-nowrap"><%= format_bytes(@attachment.byte_size) %></span>
    </.link>
    """
  end

  @doc """
  Renders filename and rows count with optional download badge for an attachment.
  """
  attr :attachment, Attachment, default: nil, doc: "the attachment to display"
  attr :badge, :boolean, default: false, doc: "whether to show the download badge"
  attr :rows, :integer, default: nil, doc: "the number of rows in the attachment"
  attr :show_file_name, :boolean, default: true, doc: "whether to show the file name"

  def file_info(%{show_file_name: true} = assigns) do
    ~H"""
    <div class="font-mono"><%= if is_nil(@attachment), do: "-", else: @attachment.filename %></div>
    <.maybe_badge_with_rows attachment={@attachment} badge={@badge} rows={@rows} />
    """
  end

  def file_info(%{show_file_name: false} = assigns) do
    ~H"""
    <.maybe_badge_with_rows attachment={@attachment} badge={@badge} rows={@rows} />
    """
  end

  defp maybe_badge_with_rows(%{badge: true, attachment: attachment} = assigns) when attachment != nil do
    ~H"""
    <div class="text-base-content/60 flex items-center gap-x-2 text-xs">
      <.attachment_download_badge attachment={@attachment} />
      <%= format_number(@rows) %> <%= ~t"rows"m %>
    </div>
    """
  end

  defp maybe_badge_with_rows(assigns) do
    ~H"""
    <div class="text-base-content/60 text-xs">
      <%= format_number(@rows) %> <%= ~t"rows"m %>
    </div>
    """
  end
end
