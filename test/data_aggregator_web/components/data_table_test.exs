defmodule DataAggregatorWeb.Components.DataTableTest do
  @moduledoc false
  use DataAggregator.DataCase, async: false

  alias DataAggregatorWeb.Components.DataTable
  alias Pagify.Factory.Api
  alias Pagify.Factory.Post

  describe "query/2" do
    setup do
      posts = [
        %{name: "Post 2", comments: ["Second", "Third", "Fourth"]},
        %{name: "Post 1", comments: ["First"]},
        %{name: "Post 3", comments: ["Second", "Third"]}
      ]

      Api.bulk_create(posts, Post, :create)
      :ok
    end

    test "sorting by name" do
      params = %{"sort" => "name"}
      assert_post_names(params, ["Post 1", "Post 2", "Post 3"])
    end

    test "sorting by -name" do
      params = %{"sort" => "-name"}
      assert_post_names(params, ["Post 3", "Post 2", "Post 1"])
    end

    test "sorting by calculation" do
      params = %{"sort" => "comments_count"}
      assert_post_names(params, ["Post 1", "Post 3", "Post 2"])
    end

    test "filtering by name" do
      params = %{"filter" => %{"name" => %{"in" => ["Post 1"]}}}
      assert_post_names(params, ["Post 1"])
    end

    test "filter by relation attribute" do
      params = %{"filter" => %{"comments" => %{"body" => "First"}}}
      assert_post_names(params, ["Post 1"])
    end

    test "paginate with limit" do
      params = %{"limit" => "10", "sort" => "name"}
      assert_post_names(params, ["Post 1", "Post 2", "Post 3"])
      assert_page_opts(params, limit: 10)
    end

    test "paginate with limit and offset" do
      params = %{"limit" => "2", "offset" => "1", "sort" => "name"}
      assert_post_names(params, ["Post 2", "Post 3"])
      assert_page_opts(params, limit: 2, offset: 1)
    end

    test "paginate with limit and offset and filter" do
      params = %{
        "limit" => "2",
        "offset" => "1",
        "sort" => "name",
        "filter" => %{"name" => %{"in" => ["Post 1", "Post 3"]}}
      }

      assert_post_names(params, ["Post 3"])
      assert_page_opts(params, limit: 2, offset: 1)
    end

    def assert_post_names(params, names) do
      opts = DataTable.read_opts(Post, params)

      assert {:ok, result} = Post.read(opts)

      posts =
        case result do
          %Ash.Page.Offset{results: posts} -> posts
          posts -> posts
        end

      assert Enum.map(posts, & &1.name) == names
    end

    def assert_page_opts(params, expected) do
      opts = DataTable.read_opts(Post, params)
      page_opts = Keyword.get(opts, :page, [])
      assert_lists_equal(expected, page_opts)
    end
  end
end
