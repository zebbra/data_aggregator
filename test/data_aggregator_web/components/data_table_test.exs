defmodule DataAggregatorWeb.Components.DataTableTest do
  use DataAggregator.DataCase, async: false

  alias __MODULE__
  alias DataAggregatorWeb.Components.DataTable

  defmodule Post do
    @moduledoc false
    use Ash.Resource, data_layer: Ash.DataLayer.Ets

    ets do
      table :posts
      private? true
    end

    actions do
      read :read do
        primary? true
        pagination offset?: true, countable: true, default_limit: 10, required?: false
      end

      create :create do
        primary? true
        argument :comments, {:array, :string}, allow_nil?: true
        change manage_relationship(:comments, type: :create, value_is_key: :body)
      end
    end

    code_interface do
      define_for DataTableTest.Api
      define :read
      define :create
    end

    attributes do
      uuid_primary_key :id
      attribute :name, :string, allow_nil?: false
    end

    aggregates do
      count :comments_count, :comments
    end

    relationships do
      has_many :comments, DataTableTest.Comment
    end
  end

  defmodule Comment do
    @moduledoc false
    use Ash.Resource, data_layer: Ash.DataLayer.Ets

    ets do
      table :comments
      private? true
    end

    actions do
      defaults [:create, :read]
    end

    attributes do
      uuid_primary_key :id
      attribute :body, :string, allow_nil?: false
    end

    relationships do
      belongs_to :post, DataTableTest.Post do
        allow_nil? false
      end
    end
  end

  defmodule Registry do
    @moduledoc false
    use Ash.Registry

    entries do
      entry DataTableTest.Post
      entry DataTableTest.Comment
    end
  end

  defmodule Api do
    @moduledoc false
    use Ash.Api

    resources do
      registry DataTableTest.Registry
    end
  end

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

    # TODO: Does currently not work with ETS
    @tag :pending
    test "sorting by comments_count" do
      params = %{"sort" => "comments_count"}
      assert_post_names(params, ["Post 1", "Post 3", "Post 2"])
    end

    test "filtering by name" do
      params = %{"filter" => %{"name" => %{"in" => ["Post 1"]}}}
      assert_post_names(params, ["Post 1"])
    end

    # TODO: Does currently not work with ETS
    @tag :pending
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
