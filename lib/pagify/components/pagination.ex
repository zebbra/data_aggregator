defmodule Pagify.Components.Pagination do
  @moduledoc false

  alias Pagify.Components
  alias Pagify.Components.Misc
  alias Pagify.Meta

  @spec default_opts() :: [Pagify.Components.pagination_option()]
  def default_opts do
    [
      current_link_attrs: [
        class: "join-item btn btn-sm btn-active max-sm:hidden",
        aria: [current: "page"]
      ],
      disabled_class: "text-base-content/20 pointer-events-none",
      ellipsis_attrs: [
        class: "join-item btn btn-sm text-base-content/20 pointer-events-none max-sm:hidden"
      ],
      ellipsis_content: Phoenix.HTML.raw("&hellip;"),
      next_link_attrs: [
        aria: [label: "Go to next page"],
        class: "join-item btn btn-sm"
      ],
      next_link_content: "Next",
      page_links: {:ellipsis, 4},
      pagination_link_aria_label: &"Go to page #{&1}",
      pagination_link_attrs: [class: "join-item btn btn-sm max-sm:hidden"],
      previous_link_attrs: [
        aria: [label: "Go to previous page"],
        class: "join-item btn btn-sm"
      ],
      previous_link_content: "Prev",
      wrapper_attrs: [
        class: "join",
        role: "navigation",
        aria: [label: "pagination"]
      ]
    ]
  end

  def merge_opts(opts) do
    Misc.deep_merge(default_opts(), opts)
  end

  def max_pages(:all, total_pages), do: total_pages
  def max_pages(:hide, _), do: 0
  def max_pages({:ellipsis, max_pages}, _), do: max_pages

  def get_page_link_range(current_page, max_pages, total_pages) do
    # number of additional pages to show before or after current page
    additional = ceil(max_pages / 2)

    cond do
      max_pages >= total_pages ->
        1..total_pages

      current_page + additional > total_pages ->
        (total_pages - max_pages + 1)..total_pages

      true ->
        first = max(current_page - additional + 1, 1)
        last = min(first + max_pages - 1, total_pages)
        first..last
    end
  end

  @spec build_page_link_helper(Meta.t(), Components.pagination_path()) ::
          (integer() -> String.t() | nil)
  def build_page_link_helper(_meta, nil), do: fn _offset -> nil end

  def build_page_link_helper(%Meta{} = meta, path) do
    query_params = build_query_params(meta)

    fn offset ->
      params = maybe_put_offset(query_params, offset)
      Components.build_path(path, params)
    end
  end

  defp build_query_params(%Meta{} = meta) do
    Components.to_query(meta.pagify, for: meta.resource)
  end

  defp maybe_put_offset(params, 0), do: Keyword.delete(params, :offset)
  defp maybe_put_offset(params, offset), do: Keyword.put(params, :offset, offset)

  def attrs_for_page_link(page, %{current_page: page}, opts) do
    add_page_link_aria_label(opts[:current_link_attrs], page, opts)
  end

  def attrs_for_page_link(page, _meta, opts) do
    add_page_link_aria_label(opts[:pagination_link_attrs], page, opts)
  end

  defp add_page_link_aria_label(attrs, page, opts) do
    aria_label = opts[:pagination_link_aria_label].(page)

    Keyword.update(
      attrs,
      :aria,
      [label: aria_label],
      &Keyword.put(&1, :label, aria_label)
    )
  end
end
