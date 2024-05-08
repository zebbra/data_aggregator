defmodule Pagify.ComponentsTest do
  @moduledoc false

  use ExUnit.Case
  use Phoenix.Component

  import Pagify.Components
  import Pagify.Factory
  import Pagify.TestHelpers
  import Phoenix.LiveViewTest

  alias Pagify.Factory.Post
  alias Phoenix.LiveView.JS
  alias Plug.Conn.Query

  doctest Pagify.Components, import: true

  @route_helper_opts [%{}, :posts]

  def route_helper(%{}, action, query) do
    URI.to_string(%URI{path: "/#{action}", query: Query.encode(query)})
  end

  def path_func(params) do
    {offset, params} = Keyword.pop(params, :offset)
    query = Query.encode(params)
    if offset, do: "/posts/page/#{offset}?#{query}", else: "/posts?#{query}"
  end

  describe "pagination/1" do
    test "renders pagination wrapper" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={%JS{}} />
        """)

      nav = find_one(html, "nav:root")

      assert attribute(nav, "aria-label") == "pagination"
      assert attribute(nav, "class") == "join"
      assert attribute(nav, "role") == "navigation"
    end

    test "does not render anything if there is only one page" do
      assigns = %{meta: build(:meta_one_page)}

      assert parse_heex(~H"""
             <Pagify.Components.pagination meta={@meta} on_paginate={%JS{}} />
             """) == []
    end

    test "does not render anything if there are no results" do
      assigns = %{meta: build(:meta_no_results)}

      assert parse_heex(~H"""
             <Pagify.Components.pagination meta={@meta} on_paginate={%JS{}} />
             """) == []
    end

    test "allows to overwrite wrapper class" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          on_paginate={%JS{}}
          opts={[wrapper_attrs: [class: "boo"]]}
        />
        """)

      nav = find_one(html, "nav:root")

      assert attribute(nav, "aria-label") == "pagination"
      assert attribute(nav, "class") == "boo"
      assert attribute(nav, "role") == "navigation"
    end

    test "allows to add attributes to wrapper" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          on_paginate={%JS{}}
          opts={[wrapper_attrs: [title: "paginate"]]}
        />
        """)

      nav = find_one(html, "nav:root")

      assert attribute(nav, "aria-label") == "pagination"
      assert attribute(nav, "class") == "join"
      assert attribute(nav, "role") == "navigation"
      assert attribute(nav, "title") == "paginate"
    end

    test "renders previous link" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      a = find_one(html, "a:fl-contains('Prev')")

      assert attribute(a, "class") == "join-item btn btn-sm"
      assert attribute(a, "data-phx-link") == "patch"
      assert attribute(a, "data-phx-link-state") == "push"
      assert attribute(a, "href") == "/posts?limit=10"
    end

    test "uses phx-click with on_paginate without path" do
      assigns = %{
        meta: build(:meta_on_second_page),
        on_paginate: JS.push("paginate")
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={@on_paginate} />
        """)

      a = find_one(html, "a:fl-contains('Prev')")

      assert attribute(a, "class") == "join-item btn btn-sm"
      assert attribute(a, "data-phx-link") == nil
      assert attribute(a, "data-phx-link-state") == nil
      assert attribute(a, "href") == "#"
      assert attribute(a, "phx-value-offset") == "0"
      assert phx_click = attribute(a, "phx-click")
      assert Jason.decode!(phx_click) == [["push", %{"event" => "paginate"}]]

      a = find_one(html, "a:fl-contains('Next')")

      assert attribute(a, "class") == "join-item btn btn-sm"
      assert attribute(a, "data-phx-link") == nil
      assert attribute(a, "data-phx-link-state") == nil
      assert attribute(a, "href") == "#"
      assert attribute(a, "phx-value-offset") == "20"
      assert phx_click = attribute(a, "phx-click")
      assert Jason.decode!(phx_click) == [["push", %{"event" => "paginate"}]]
    end

    test "uses phx-click with on_paginate and path" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" on_paginate={JS.push("paginate")} />
        """)

      a = find_one(html, "a:fl-contains('Prev')")

      assert attribute(a, "class") == "join-item btn btn-sm"
      assert attribute(a, "data-phx-link") == "patch"
      assert attribute(a, "data-phx-link-state") == "push"
      assert attribute(a, "href") == "/posts?limit=10"
      assert attribute(a, "phx-value-offset") == "0"
      assert phx_click = attribute(a, "phx-click")
      assert Jason.decode!(phx_click) == [["push", %{"event" => "paginate"}]]
    end

    test "supports a function/args tuple as path" do
      assigns = %{
        meta: build(:meta_on_second_page),
        path: {&route_helper/3, @route_helper_opts}
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path={@path} />
        """)

      assert a = find_one(html, "a:fl-contains('Prev')")
      assert attribute(a, "href") == "/posts?limit=10"
    end

    test "supports a function as path" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path={&path_func/1} />
        """)

      assert a = find_one(html, "a:fl-contains('Next')")
      assert attribute(a, "href") == "/posts/page/10?limit=10"
    end

    test "supports a URI string as path" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      assert a = find_one(html, "a:fl-contains('Prev')")
      assert attribute(a, "href") == "/posts?limit=10"
    end

    test "adds phx-target to previous link" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} target="here" />
        """)

      assert a = find_one(html, "a:fl-contains('Prev')")
      assert attribute(a, "phx-target") == "here"
    end

    test "merges query parameters into existing parameters" do
      assigns = %{
        meta: build(:meta_on_second_page),
        path: {&route_helper/3, @route_helper_opts ++ [[category: "dinosaurs"]]}
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path={@path} />
        """)

      assert previous = find_one(html, "a:fl-contains('Prev')")
      assert attribute(previous, "class") == "join-item btn btn-sm"
      assert attribute(previous, "data-phx-link") == "patch"
      assert attribute(previous, "data-phx-link-state") == "push"

      assert a = attribute(previous, "href")
      assert_urls_match(a, "/posts?category=dinosaurs&limit=10")
    end

    test "merges query parameters into existing path query parameters" do
      assigns = %{
        meta: build(:meta_on_second_page),
        path: {&route_helper/3, @route_helper_opts ++ [[category: "dinosaurs"]]}
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts?category=dinosaurs" />
        """)

      assert previous = find_one(html, "a:fl-contains('Prev')")
      assert attribute(previous, "class") == "join-item btn btn-sm"
      assert attribute(previous, "data-phx-link") == "patch"
      assert attribute(previous, "data-phx-link-state") == "push"

      assert href = attribute(previous, "href")
      assert_urls_match(href, "/posts?limit=10&category=dinosaurs")
    end

    test "allows to overwrite previous link attributes and content" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[
            previous_link_attrs: [class: "prev", title: "p-p-previous"],
            previous_link_content: Phoenix.HTML.raw(~s(<i class="fas fa-chevron-left" />))
          ]}
        />
        """)

      assert link = find_one(html, "a[title='p-p-previous']")
      assert attribute(link, "class") == "prev"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert attribute(link, "href") == "/posts?limit=10"

      assert link |> Floki.children() |> Floki.raw_html() ==
               "<i class=\"fas fa-chevron-left\"></i>"
    end

    test "disables previous link if on first page" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      assert previous_link = find_one(html, "span:fl-contains('Prev')")

      assert attribute(previous_link, "class") ==
               "join-item btn btn-sm text-base-content/20 pointer-events-none"
    end

    test "disables previous link if on first page when using click handlers" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} />
        """)

      assert previous_link = find_one(html, "span:fl-contains('Prev')")

      assert attribute(previous_link, "class") ==
               "join-item btn btn-sm text-base-content/20 pointer-events-none"
    end

    test "allows to overwrite previous link class and content if disabled" do
      assigns = %{meta: build(:meta_on_first_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[
            previous_link_attrs: [class: "prev", title: "no"],
            previous_link_content: "Previous"
          ]}
        />
        """)

      assert previous_link = find_one(html, "span:fl-contains('Previous')")

      assert attribute(previous_link, "class") == "prev text-base-content/20 pointer-events-none"
      assert attribute(previous_link, "title") == "no"
      assert text(previous_link) == "Previous"
    end

    test "renders next link" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      assert link = find_one(html, "a:fl-contains('Next')")

      assert attribute(link, "class") == "join-item btn btn-sm"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert href = attribute(link, "href")
      assert_urls_match(href, "/posts?offset=20&limit=10")
    end

    test "renders next link when using click event handling" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} />
        """)

      assert link = find_one(html, "a:fl-contains('Next')")

      assert attribute(link, "class") == "join-item btn btn-sm"
      assert attribute(link, "phx-value-offset") == "20"
      assert attribute(link, "href") == "#"
      assert phx_click = attribute(link, "phx-click")
      assert Jason.decode!(phx_click) == [["push", %{"event" => "paginate"}]]
    end

    test "adds phx-target to next link" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} target="here" />
        """)

      assert link = find_one(html, "a:fl-contains('Next')")
      assert attribute(link, "phx-target") == "here"
    end

    test "allows to overwrite next link attributes and content" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[
            next_link_attrs: [class: "next", title: "n-n-next"],
            next_link_content: Phoenix.HTML.raw(~s("<i class="fas fa-chevron-right" />))
          ]}
        />
        """)

      assert link = find_one(html, "a[title='n-n-next']")
      assert attribute(link, "class") == "next"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert href = attribute(link, "href")
      assert_urls_match(href, "/posts?offset=20&limit=10")

      assert attribute(link, "i", "class") == "fas fa-chevron-right"
    end

    test "disables next link if on last page" do
      assigns = %{meta: build(:meta_on_last_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      assert next = find_one(html, "span:fl-contains('Next')")

      assert attribute(next, "class") ==
               "join-item btn btn-sm text-base-content/20 pointer-events-none"

      assert attribute(next, "href") == nil
    end

    test "renders next link on last page when using click event handling" do
      assigns = %{meta: build(:meta_on_last_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} />
        """)

      assert next = find_one(html, "span:fl-contains('Next')")

      assert attribute(next, "class") ==
               "join-item btn btn-sm text-base-content/20 pointer-events-none"

      assert attribute(next, "href") == nil
    end

    test "allows to overwrite next link attributes and content when disabled" do
      assigns = %{meta: build(:meta_on_last_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[
            next_link_attrs: [class: "next", title: "no"],
            next_link_content: "N-n-next"
          ]}
        />
        """)

      assert next_link = find_one(html, "span:fl-contains('N-n-next')")
      assert attribute(next_link, "class") == "next text-base-content/20 pointer-events-none"
      assert attribute(next_link, "title") == "no"
    end

    test "renders page links" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      assert link = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(link, "class") == "join-item btn btn-sm max-sm:hidden"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert attribute(link, "href") == "/posts?limit=10"
      assert text(link) == "1"

      assert link = find_one(html, "a[aria-label='Go to page 2']")
      assert attribute(link, "class") == "join-item btn btn-sm btn-active max-sm:hidden"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert href = attribute(link, "href")
      assert_urls_match(href, "/posts?offset=10&limit=10")
      assert text(link) == "2"

      assert link = find_one(html, "a[aria-label='Go to page 3']")
      assert attribute(link, "class") == "join-item btn btn-sm max-sm:hidden"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert href = attribute(link, "href")
      assert_urls_match(href, "/posts?offset=20&limit=10")
      assert text(link) == "3"
    end

    test "renders page links when using click event handling" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} />
        """)

      assert link = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(link, "href") == "#"
      assert attribute(link, "phx-value-offset") == "0"
      assert text(link) =~ "1"
      assert phx_click = attribute(link, "phx-click")
      assert Jason.decode!(phx_click) == [["push", %{"event" => "paginate"}]]
    end

    test "adds phx-target to page link" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} target="here" />
        """)

      assert link = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(link, "phx-target") == "here"
    end

    test "doesn't render pagination links if set to hide" do
      assigns = %{meta: build(:meta_on_second_page), opts: [page_links: :hide]}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert find_one(html, "a[aria-label='Go to previous page']")
      assert Floki.find(html, "a[aria-label='Go to page 1']") == []
    end

    test "doesn't render pagination links if set to hide when passing event" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          on_paginate={JS.push("paginate")}
          opts={[page_links: :hide]}
        />
        """)

      assert find_one(html, "a[aria-label='Go to previous page']")
      assert Floki.find(html, "a[aria-label='Go to page 1']") == []
    end

    test "allows to overwrite pagination link attributes" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[pagination_link_attrs: [class: "p-link", beep: "boop"]]}
        />
        """)

      assert link = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(link, "beep") == "boop"
      assert attribute(link, "class") == "p-link"

      # current link attributes are unchanged
      assert link = find_one(html, "a[aria-label='Go to page 2']")
      assert attribute(link, "beep") == nil
      assert attribute(link, "class") == "join-item btn btn-sm btn-active max-sm:hidden"
    end

    test "allows to overwrite current attributes" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[current_link_attrs: [class: "link is-active", beep: "boop"]]}
        />
        """)

      assert link = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(link, "class") == "join-item btn btn-sm max-sm:hidden"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert attribute(link, "href") == "/posts?limit=10"
      assert text(link) == "1"

      assert link = find_one(html, "a[aria-label='Go to page 2']")
      assert attribute(link, "beep") == "boop"
      assert attribute(link, "class") == "link is-active"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert href = attribute(link, "href")
      assert_urls_match(href, "/posts?offset=10&limit=10")
      assert text(link) == "2"
    end

    test "allows to overwrite pagination link aria label" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination
          meta={@meta}
          path="/posts"
          opts={[pagination_link_aria_label: &"On to page #{&1}"]}
        />
        """)

      assert link = find_one(html, "a[aria-label='On to page 1']")
      assert attribute(link, "class") == "join-item btn btn-sm max-sm:hidden"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert attribute(link, "href") == "/posts?limit=10"
      assert text(link) == "1"

      assert link = find_one(html, "a[aria-label='On to page 2']")
      assert attribute(link, "class") == "join-item btn btn-sm btn-active max-sm:hidden"
      assert attribute(link, "data-phx-link") == "patch"
      assert attribute(link, "data-phx-link-state") == "push"
      assert href = attribute(link, "href")
      assert_urls_match(href, "/posts?offset=10&limit=10")
      assert text(link) == "2"
    end

    test "adds order parameters to links" do
      assigns = %{
        meta:
          build(
            :meta_on_second_page,
            pagify: %Pagify{
              order_by: [name: :asc, author: :desc],
              offset: 10,
              limit: 10
            }
          )
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      default_query = [
        limit: 10,
        order_by: ["name", "-author"]
      ]

      expected_query = fn
        1 -> default_query
        offset -> Keyword.put(default_query, :offset, offset)
      end

      assert previous = find_one(html, "a:fl-contains('Prev')")
      assert attribute(previous, "class") == "join-item btn btn-sm"
      assert attribute(previous, "data-phx-link") == "patch"
      assert attribute(previous, "data-phx-link-state") == "push"
      assert href = attribute(previous, "href")
      assert_urls_match(href, "/posts", expected_query.(1))

      assert one = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(one, "class") == "join-item btn btn-sm max-sm:hidden"
      assert attribute(one, "data-phx-link") == "patch"
      assert attribute(one, "data-phx-link-state") == "push"
      assert href = attribute(one, "href")
      assert_urls_match(href, "/posts", expected_query.(1))

      assert next = find_one(html, "a:fl-contains('Next')")
      assert attribute(next, "class") == "join-item btn btn-sm"
      assert attribute(next, "data-phx-link") == "patch"
      assert attribute(next, "data-phx-link-state") == "push"
      assert href = attribute(next, "href")
      assert_urls_match(href, "/posts", expected_query.(20))
    end

    test "hides default order and limit" do
      assigns = %{
        meta:
          build(
            :meta_on_second_page,
            pagify: %Pagify{
              limit: 15,
              order_by: [id: :asc]
            },
            resource: Post
          )
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      assert prev = find_one(html, "a:fl-contains('Prev')")
      assert href = attribute(prev, "href")

      refute href =~ "limit="
      refute href =~ "order_by[]="
    end

    test "does not require path when passing event" do
      assigns = %{meta: build(:meta_on_second_page)}

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} on_paginate={JS.push("paginate")} />
        """)

      assert link = find_one(html, "a:fl-contains('Prev')")
      assert attribute(link, "class") == "join-item btn btn-sm"
      assert attribute(link, "phx-value-offset") == "0"
      assert attribute(link, "href") == "#"
      assert phx_click = attribute(link, "phx-click")
      assert Jason.decode!(phx_click) == [["push", %{"event" => "paginate"}]]
    end

    test "raises if neither path nor on_paginate are passed" do
      assigns = %{meta: build(:meta_on_second_page)}

      assert_raise Pagify.Error.Components.PathOrJSError,
                   fn ->
                     rendered_to_string(~H"""
                     <Pagify.Components.pagination meta={@meta} />
                     """)
                   end
    end

    test "adds filter parameters to links" do
      assigns = %{
        meta:
          build(
            :meta_on_second_page,
            pagify: %Pagify{
              offset: 10,
              limit: 10,
              filters: %{
                and: [
                  %{comments_count: %{gte: 2}},
                  %{comments_count: %{lte: 5}}
                ],
                name: %{in: ["Post 1", "Post 2"]}
              }
            },
            resource: Post
          )
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" />
        """)

      default_query = [
        limit: 10,
        filters: %{
          and: [
            %{comments_count: %{gte: 2}},
            %{comments_count: %{lte: 5}}
          ],
          name: %{in: ["Post 1", "Post 2"]}
        }
      ]

      expected_query = fn
        1 -> default_query
        offset -> Keyword.put(default_query, :offset, offset)
      end

      assert previous = find_one(html, "a:fl-contains('Prev')")
      assert attribute(previous, "class") == "join-item btn btn-sm"
      assert attribute(previous, "data-phx-link") == "patch"
      assert attribute(previous, "data-phx-link-state") == "push"
      assert href = attribute(previous, "href")
      assert_urls_match(href, "/posts", expected_query.(1))

      assert one = find_one(html, "a[aria-label='Go to page 1']")
      assert attribute(one, "class") == "join-item btn btn-sm max-sm:hidden"
      assert attribute(one, "data-phx-link") == "patch"
      assert attribute(one, "data-phx-link-state") == "push"
      assert href = attribute(one, "href")
      assert_urls_match(href, "/posts", expected_query.(1))

      assert next = find_one(html, "a:fl-contains('Next')")
      assert attribute(next, "class") == "join-item btn btn-sm"
      assert attribute(next, "data-phx-link") == "patch"
      assert attribute(next, "data-phx-link-state") == "push"
      assert href = attribute(next, "href")
      assert_urls_match(href, "/posts", expected_query.(20))
    end

    test "does not render ellipsis if total pages <= max pages" do
      # max pages smaller than total pages
      assigns = %{
        meta: build(:meta_on_second_page),
        opts: [page_links: {:ellipsis, 50}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert Floki.find(html, "span[aria-hidden='true']") == []
      assert html |> Floki.find(".join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 5

      # max pages equal to total pages
      assigns = %{
        meta: build(:meta_on_second_page),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert Floki.find(html, "span[aria-hidden='true']") == []
      assert html |> Floki.find(".join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 5
    end

    test "renders end ellipsis and last page link when on page 1" do
      assigns = %{
        meta: build(:meta_on_first_page, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 1
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 6

      assert find_one(html, "a[aria-label='Go to page 20']")

      for i <- 1..5 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders start ellipsis and first page link when on last page" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 20, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 1
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 6

      assert find_one(html, "a[aria-label='Go to page 1']")

      for i <- 16..20 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on even page with even number of max pages" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 12, total_pages: 20),
        opts: [page_links: {:ellipsis, 6}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 2
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 8

      assert find_one(html, "a[aria-label='Go to page 1']")
      assert find_one(html, "a[aria-label='Go to page 20']")

      for i <- 10..15 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on odd page with odd number of max pages" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 11, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 2
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 7

      assert find_one(html, "a[aria-label='Go to page 1']")
      assert find_one(html, "a[aria-label='Go to page 20']")

      for i <- 9..13 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on even page with odd number of max pages" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 10, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 2
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 7

      assert find_one(html, "a[aria-label='Go to page 1']")
      assert find_one(html, "a[aria-label='Go to page 20']")

      for i <- 8..12 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders ellipses when on odd page with even number of max pages" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 11, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 2
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 7

      assert find_one(html, "a[aria-label='Go to page 1']")
      assert find_one(html, "a[aria-label='Go to page 20']")

      for i <- 9..13 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders end ellipsis when on page close to the beginning" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 2, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 1
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 6

      assert find_one(html, "a[aria-label='Go to page 20']")

      for i <- 1..5 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "renders start ellipsis when on page close to the end" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 18, total_pages: 20),
        opts: [page_links: {:ellipsis, 5}]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert html |> Floki.find("span[aria-hidden='true']") |> length() == 1
      assert html |> Floki.find("a.join-item.btn.btn-sm.max-sm\\:hidden") |> length() == 6

      assert find_one(html, "a[aria-label='Go to page 1']")

      for i <- 16..20 do
        assert find_one(html, "a[aria-label='Go to page #{i}']")
      end
    end

    test "allows to overwrite ellipsis attributes and content" do
      assigns = %{
        meta: build(:meta_on_first_page, current_page: 10, total_pages: 20),
        opts: [
          page_links: {:ellipsis, 5},
          ellipsis_attrs: [class: "dotdotdot", title: "dot"],
          ellipsis_content: "dot dot dot"
        ]
      }

      html =
        parse_heex(~H"""
        <Pagify.Components.pagination meta={@meta} path="/posts" opts={@opts} />
        """)

      assert [el, _] = Floki.find(html, "span[class='dotdotdot']")
      assert text(el) == "dot dot dot"
    end

    test "does not render anything if meta has errors" do
      {:error, meta} = Pagify.validate(Post, %{offset: -1})
      assigns = %{meta: meta}

      assert parse_heex(~H"""
             <Pagify.Components.pagination meta={@meta} path="/posts" />
             """) == []
    end
  end

  describe "to_query/2" do
    test "does not add empty values" do
      refute %Pagify{limit: nil} |> to_query() |> Keyword.has_key?(:limit)
      refute %Pagify{order_by: []} |> to_query() |> Keyword.has_key?(:order_by)
      refute %Pagify{filters: %{}} |> to_query() |> Keyword.has_key?(:filters)
    end

    test "does not add params for first page/offset" do
      refute %Pagify{offset: 0} |> to_query() |> Keyword.has_key?(:offset)
    end

    test "does not add limit/page_size if it matches default" do
      opts = [default_limit: 20]

      assert %Pagify{limit: 10}
             |> to_query(opts)
             |> Keyword.has_key?(:limit)

      refute %Pagify{limit: 20}
             |> to_query(opts)
             |> Keyword.has_key?(:limit)
    end

    test "does not order params if they match the default" do
      opts = [
        default_order: [id: :asc]
      ]

      # order_by does not match default
      query =
        to_query(
          %Pagify{order_by: [name: :asc]},
          opts
        )

      assert Keyword.has_key?(query, :order_by)

      # order_by matches default
      query =
        to_query(
          %Pagify{order_by: [id: :asc]},
          opts
        )

      refute Keyword.has_key?(query, :order_by)
    end
  end

  describe "build_path/3" do
    test "gets the for option from the meta struct to retrieve defaults" do
      meta = %Pagify.Meta{resource: Post, pagify: %Pagify{limit: 21}}
      assert build_path("/posts", meta) == "/posts?limit=21"

      meta = %Pagify.Meta{resource: Post, pagify: %Pagify{limit: 15}}
      assert build_path("/posts", meta) == "/posts"
    end
  end
end
