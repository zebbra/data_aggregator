defmodule PagifyTest do
  @moduledoc false
  use DataAggregator.DataCase, async: false

  alias Pagify.Factory.Api
  alias Pagify.Factory.Comment
  alias Pagify.Factory.Post
  alias Pagify.Meta

  require Ash.Query

  doctest Pagify, import: true

  setup do
    posts = [
      %{name: "Post 2", comments: ["Second", "Third", "Fourth", "Another"]},
      %{name: "Post 1", author: "John", comments: ["First", "Second"]},
      %{name: "Post 3", author: "Doe", comments: ["Second", "Third", "Another"]}
    ]

    Api.bulk_create(posts, Post, :create)
    :ok
  end

  describe "ordering" do
    test "orders by name :asc" do
      pagify = %Pagify{order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
    end

    test "orders by name :desc" do
      pagify = %Pagify{order_by: {:name, :desc}}
      assert_post_names(pagify, ["Post 3", "Post 2", "Post 1"])
    end

    test "orders by author :asc_nils_first" do
      pagify = %Pagify{order_by: {:author, :asc_nils_first}}
      assert_post_names(pagify, ["Post 2", "Post 3", "Post 1"])
    end

    test "orders by author :desc_nils_last" do
      pagify = %Pagify{order_by: {:author, :desc_nils_last}}
      assert_post_names(pagify, ["Post 1", "Post 3", "Post 2"])
    end

    test "orders by calculation" do
      pagify = %Pagify{order_by: :comments_count}
      assert_post_names(pagify, ["Post 1", "Post 3", "Post 2"])
    end

    test "orders by calculation :desc" do
      pagify = %Pagify{order_by: {:comments_count, :desc}}
      assert_post_names(pagify, ["Post 2", "Post 3", "Post 1"])
    end

    test "orders by multiple fields" do
      pagify = %Pagify{order_by: [{:name, :asc}, {:comments_count, :desc}]}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
    end
  end

  describe "filtering" do
    test "applies 'is_nil' filter" do
      pagify = %Pagify{filters: %{"author" => %{"is_nil" => true}}, order_by: :name}
      assert_post_names(pagify, ["Post 2"])
    end

    test "applies `equals` filter" do
      pagify = %Pagify{filters: %{"name" => %{"equals" => "Post 1"}}, order_by: :name}
      assert_post_names(pagify, ["Post 1"])
    end

    test "applies equality '==' filter" do
      pagify = %Pagify{filters: %{"name" => %{"==" => "Post 1"}}, order_by: :name}
      assert_post_names(pagify, ["Post 1"])
    end

    test "applies inherit equality filter" do
      pagify = %Pagify{filters: %{"author" => "John"}, order_by: :name}
      assert_post_names(pagify, ["Post 1"])
    end

    test "applies inequality 'not_equals' filter" do
      pagify = %Pagify{filters: %{"author" => %{"not_equals" => "John"}}, order_by: :name}
      assert_post_names(pagify, ["Post 3"])
    end

    test "applies inequality '!=' filter" do
      pagify = %Pagify{filters: %{"author" => %{"!=" => "John"}}, order_by: :name}
      assert_post_names(pagify, ["Post 3"])
    end

    test "applies greater than 'gt' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{"gt" => 2}}, order_by: :name}
      assert_post_names(pagify, ["Post 2", "Post 3"])
    end

    test "applies greater than '>' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{">" => 2}}, order_by: :name}
      assert_post_names(pagify, ["Post 2", "Post 3"])
    end

    test "applies greater than or equal 'gte' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{"gte" => 2}}, order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
    end

    test "applies greater than or equal '>=' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{">=" => 2}}, order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
    end

    test "applies less than 'lt' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{"lt" => 3}}, order_by: :name}
      assert_post_names(pagify, ["Post 1"])
    end

    test "applies less than '<' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{"<" => 3}}, order_by: :name}
      assert_post_names(pagify, ["Post 1"])
    end

    test "applies less than or equal 'lte' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{"lte" => 3}}, order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 3"])
    end

    test "applies less than or equal '<=' filter" do
      pagify = %Pagify{filters: %{"comments_count" => %{"<=" => 3}}, order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 3"])
    end

    test "applies and filter" do
      pagify = %Pagify{
        filters: %{"and" => [%{"author" => "John"}, %{"comments_count" => %{"gt" => 1}}]},
        order_by: :name
      }

      assert_post_names(pagify, ["Post 1"])
    end

    test "applies inherit and filter" do
      pagify = %Pagify{
        filters: %{
          "author" => "John",
          "comments_count" => %{"gt" => 1}
        },
        order_by: :name
      }

      assert_post_names(pagify, ["Post 1"])
    end

    test "applies or filter" do
      pagify = %Pagify{
        filters: %{"or" => [%{"author" => "John"}, %{"comments_count" => %{"gt" => 3}}]},
        order_by: :name
      }

      assert_post_names(pagify, ["Post 1", "Post 2"])
    end

    test "applies nested 'or' and 'and' filter" do
      pagify = %Pagify{
        filters: %{
          "or" => [
            %{"author" => "John"},
            %{
              "and" => [
                %{"comments_count" => %{"gt" => 2}},
                %{"name" => %{"in" => ["Post 2", "Post 3"]}}
              ]
            }
          ]
        },
        order_by: :name
      }

      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
    end

    test "filters by relation attribute" do
      pagify = %Pagify{
        filters: %{"comments" => %{"body" => "First"}},
        order_by: :name
      }

      assert_post_names(pagify, ["Post 1"])
    end
  end

  describe "offset pagination" do
    test "pagination with limit" do
      pagify = %Pagify{limit: 10, order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
      assert_page_opts(pagify, [limit: 10, offset: 0, count: true], [])
    end

    test "pagination with limit and offset" do
      pagify = %Pagify{limit: 2, offset: 1, order_by: :name}
      assert_post_names(pagify, ["Post 2", "Post 3"])
      assert_page_opts(pagify, [limit: 2, offset: 1, count: true], [])
    end

    test "pagination with disabled count" do
      pagify = %Pagify{limit: 2, offset: 1, order_by: :name}
      assert_post_names(pagify, ["Post 2", "Post 3"], page: [count: false])
      assert_page_opts(pagify, [limit: 2, offset: 1, count: false], page: [count: false])
    end

    test "pagination with default limit from resource" do
      pagify = %Pagify{order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"])
      assert_page_opts(pagify, [limit: 15, offset: 0, count: true], [])
    end

    test "pagination with default limit from resource and offset" do
      pagify = %Pagify{offset: 1, order_by: :name}
      assert_post_names(pagify, ["Post 2", "Post 3"])
      assert_page_opts(pagify, [limit: 15, offset: 1, count: true], [])
    end

    test "pagination with default limit from resource and disabled count" do
      pagify = %Pagify{order_by: :name}
      assert_post_names(pagify, ["Post 1", "Post 2", "Post 3"], page: [count: false])
      assert_page_opts(pagify, [limit: 15, offset: 0, count: false], page: [count: false])
    end

    test "pagination with default limit from resource and offset and disabled count" do
      pagify = %Pagify{offset: 1, order_by: :name}
      assert_post_names(pagify, ["Post 2", "Post 3"], page: [count: false])
      assert_page_opts(pagify, [limit: 15, offset: 1, count: false], page: [count: false])
    end

    test "pagination with default limit from pagify" do
      pagify = %Pagify{order_by: :body}

      assert_comment_names(pagify, [
        "Another",
        "Another",
        "First",
        "Fourth",
        "Second",
        "Second",
        "Second",
        "Third",
        "Third"
      ])

      assert_comment_page_opts(pagify, [limit: 25, offset: 0, count: true], [])
    end
  end

  describe "all/4" do
    test "returns all matching posts" do
      pagify = %Pagify{
        limit: 2,
        offset: 2,
        order_by: :name,
        filters: %{"name" => %{"in" => ["Post 1", "Post 2", "Post 3"]}}
      }

      assert_post_names(pagify, ["Post 3"])
    end
  end

  describe "count/2" do
    test "returns count of matching entries" do
      pagify = %Pagify{
        limit: 2,
        offset: 2,
        order_by: [:age],
        filters: %{comments_count: %{lte: 3}}
      }

      assert Pagify.count(Post, pagify) == 2
    end

    test "allows overriding query" do
      pagify = %Pagify{
        limit: 2,
        offset: 2,
        order_by: [:age],
        filters: %{comments_count: %{lte: 3}}
      }

      # default query
      assert Pagify.count(Post, pagify) == 2

      # custom count query
      assert Pagify.count(
               Post,
               pagify,
               count_query: Ash.Query.filter_input(Post, %{name: "Post 2"})
             ) == 1
    end

    test "allows overriding the count itself" do
      pagify = %Pagify{
        limit: 2,
        offset: 2,
        order_by: [:age],
        filters: %{comments_count: %{lte: 3}}
      }

      # default query
      assert Pagify.count(Post, pagify) == 2

      # custom count
      assert Pagify.count(Post, pagify, count: 6) == 6
    end
  end

  describe "meta/3" do
    test "returns the meta information for a query with limit/offset" do
      pagify = %Pagify{limit: 3, offset: 0, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta == %Meta{
               current_limit: 3,
               current_offset: 0,
               current_page: 1,
               default_scopes: %{status: :all},
               errors: [],
               has_next_page?: false,
               has_previous_page?: false,
               next_offset: nil,
               opts: [],
               pagify: %Pagify{filters: nil, limit: 3, offset: 0, order_by: :name},
               params: %{},
               previous_offset: 0,
               resource: Post,
               total_count: 3,
               total_pages: 1
             }
    end

    test "returns the meta information for a query without limit" do
      pagify = %Pagify{}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta == %Meta{
               current_limit: 15,
               current_offset: 0,
               current_page: 1,
               default_scopes: %{status: :all},
               errors: [],
               has_next_page?: false,
               has_previous_page?: false,
               next_offset: nil,
               opts: [],
               pagify: %Pagify{},
               params: %{},
               previous_offset: 0,
               resource: Post,
               total_count: 3,
               total_pages: 1
             }
    end

    test "rounds current page if offset is between pages" do
      pagify = %Pagify{limit: 2, offset: 1, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta == %Meta{
               current_limit: 2,
               current_offset: 1,
               current_page: 2,
               default_scopes: %{status: :all},
               errors: [],
               has_next_page?: false,
               has_previous_page?: true,
               next_offset: nil,
               opts: [],
               pagify: %Pagify{limit: 2, offset: 1, order_by: :name},
               params: %{},
               previous_offset: 0,
               resource: Post,
               total_count: 3,
               total_pages: 2
             }
    end

    test "current page shouldn't be greate than total page numbers" do
      pagify = %Pagify{limit: 2, offset: 3, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta == %Meta{
               current_limit: 2,
               current_offset: 3,
               current_page: 2,
               default_scopes: %{status: :all},
               errors: [],
               has_next_page?: false,
               has_previous_page?: true,
               next_offset: nil,
               opts: [],
               pagify: %Pagify{limit: 2, offset: 3, order_by: :name},
               params: %{},
               previous_offset: 1,
               resource: Post,
               total_count: 3,
               total_pages: 2
             }
    end

    test "sets has_previous_page? and has_next_page?" do
      pagify = %Pagify{limit: 1, offset: 0, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta.has_previous_page? == false
      assert meta.has_next_page? == true

      pagify = %Pagify{limit: 1, offset: 1, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta.has_previous_page? == true
      assert meta.has_next_page? == true

      pagify = %Pagify{limit: 1, offset: 2, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta.has_previous_page? == true
      assert meta.has_next_page? == false

      pagify = %Pagify{limit: 1, offset: 3, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta.has_previous_page? == true
      assert meta.has_next_page? == false

      pagify = %Pagify{limit: 1, offset: 4, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta.has_previous_page? == true
      assert meta.has_next_page? == false
    end

    test "sets options" do
      pagify = %Pagify{limit: 1, offset: 0, order_by: :name}
      page = Pagify.all(Post, pagify)
      meta = Pagify.meta(page, pagify)

      assert meta.opts == []

      opts = [page: [count: false]]
      pagify = %Pagify{limit: 1, offset: 0, order_by: :name}
      page = Pagify.all(Post, pagify, opts)
      meta = Pagify.meta(page, pagify, opts)

      assert meta.opts == opts
    end

    test "sets default scopes" do
      pagify = %Pagify{limit: 1, offset: 0, order_by: :name}

      opts =
        Pagify.Misc.maybe_put_compiled_pagify_scopes(Post,
          pagify_scopes: %{
            role: [
              %{name: :user, filter: %{author: "Doe"}, default?: true}
            ]
          }
        )

      page = Pagify.all(Post, pagify, opts)
      meta = Pagify.meta(page, pagify, opts)

      assert meta.default_scopes == %{role: :user, status: :all}
      assert meta.opts == []
    end
  end

  describe "run/4" do
    test "returns data and meta data" do
      pagify = %Pagify{limit: 2, offset: 1, order_by: :name}
      {data, meta} = Pagify.run(Post, pagify)

      assert Enum.map(data, & &1.name) == ["Post 2", "Post 3"]

      assert meta == %Meta{
               current_limit: 2,
               current_offset: 1,
               current_page: 2,
               default_scopes: %{status: :all},
               errors: [],
               has_next_page?: false,
               has_previous_page?: true,
               next_offset: nil,
               opts: [],
               pagify: %Pagify{limit: 2, offset: 1, order_by: :name},
               params: %{},
               previous_offset: 0,
               resource: Post,
               total_count: 3,
               total_pages: 2
             }
    end
  end

  describe "validate_and_run/4" do
    test "returns error if pagify is invalid" do
      pagify = %Pagify{limit: -1, filters: %{name: "Post 1", other: "John"}}

      {:error, %Meta{} = meta} =
        Pagify.validate_and_run(Post, pagify, replace_invalid_params?: true)

      assert meta.pagify == %Pagify{}

      assert inspect(meta.params) ==
               ~s"%{offset: 0, filters: #Ash.Filter<name == \"Post 1\">, limit: 15, scopes: %{status: :all}}"

      assert [%Ash.Error.Query.InvalidLimit{limit: -1}] = Keyword.get(meta.errors, :limit)

      assert [%Ash.Error.Query.NoSuchAttributeOrRelationship{attribute_or_relationship: :other}] =
               Keyword.get(meta.errors, :filters)
    end

    test "returns error and original params if pagify is invalid" do
      pagify = %Pagify{limit: -1, filters: %{name: "Post 1", other: "John"}}

      {:error, %Meta{} = meta} =
        Pagify.validate_and_run(Post, pagify)

      assert meta.pagify == %Pagify{}

      assert %{
               limit: -1,
               filters: %{name: "Post 1", other: "John"},
               offset: 0,
               scopes: %{status: :all}
             } == meta.params

      assert [%Ash.Error.Query.InvalidLimit{limit: -1}] = Keyword.get(meta.errors, :limit)

      assert [%Ash.Error.Query.NoSuchAttributeOrRelationship{attribute_or_relationship: :other}] =
               Keyword.get(meta.errors, :filters)
    end

    test "returns data and meta data" do
      pagify = %Pagify{limit: 2, offset: 1, order_by: :name}
      {:ok, {data, meta}} = Pagify.validate_and_run(Post, pagify)

      assert Enum.map(data, & &1.name) == ["Post 2", "Post 3"]

      assert meta == %Meta{
               current_limit: 2,
               current_offset: 1,
               current_page: 2,
               default_scopes: %{status: :all},
               errors: [],
               has_next_page?: false,
               has_previous_page?: true,
               next_offset: nil,
               opts: [],
               pagify: %Pagify{
                 limit: 2,
                 offset: 1,
                 order_by: [name: :asc],
                 scopes: %{status: :all}
               },
               params: %{},
               previous_offset: 0,
               resource: Post,
               total_count: 3,
               total_pages: 2
             }
    end
  end

  describe "validate_and_run!/4" do
    test "raises if pagify is invalid" do
      assert_raise Pagify.Error.Query.InvalidParamsError, fn ->
        Pagify.validate_and_run!(Post, %Pagify{
          limit: -1,
          filters: %{name: "Post 1", other: "John"}
        })
      end
    end

    test "returns data and meta data" do
      pagify = %{limit: 1, offset: 0, order_by: :name, filters: %{"name" => "Post 2"}}

      assert {[%Post{}],
              %Pagify.Meta{
                current_limit: 1,
                current_offset: 0,
                current_page: 1,
                errors: [],
                has_next_page?: false,
                has_previous_page?: false,
                next_offset: nil,
                opts: [],
                pagify: %Pagify{},
                params: %{},
                previous_offset: 0,
                total_count: 1,
                total_pages: 1
              }} = Pagify.validate_and_run!(Post, pagify)
    end
  end

  describe "validate/1" do
    test "returns Pagify struct" do
      assert Pagify.validate(Post, %Pagify{}) ==
               {:ok, %Pagify{limit: 15, offset: 0, scopes: %{status: :all}}}

      assert Pagify.validate(Post, %{}) ==
               {:ok, %Pagify{limit: 15, offset: 0, scopes: %{status: :all}}}
    end

    test "returns error and replaced params if parameters are invalid" do
      assert {:error, %Meta{} = meta} =
               Pagify.validate(Post, %{limit: -1, filters: %{name: "Post 1", other: "John"}},
                 replace_invalid_params?: true
               )

      assert meta.pagify == %Pagify{}

      %{limit: limit, offset: offset, filters: filters} = meta.params
      assert limit == 15
      assert offset == 0
      assert inspect(filters) == ~s"#Ash.Filter<name == \"Post 1\">"

      assert [%Ash.Error.Query.InvalidLimit{limit: -1}] = Keyword.get(meta.errors, :limit)

      assert [%Ash.Error.Query.NoSuchAttributeOrRelationship{attribute_or_relationship: :other}] =
               Keyword.get(meta.errors, :filters)
    end

    test "returns error and original params if parameters are invalid" do
      assert {:error, %Meta{} = meta} =
               Pagify.validate(
                 Post,
                 %Pagify{limit: -1, filters: %{name: "Post 1", other: "John"}}
               )

      assert meta.pagify == %Pagify{}

      assert %{
               limit: -1,
               filters: %{name: "Post 1", other: "John"},
               offset: 0,
               scopes: %{status: :all}
             } == meta.params

      assert [%Ash.Error.Query.InvalidLimit{limit: -1}] = Keyword.get(meta.errors, :limit)

      assert [%Ash.Error.Query.NoSuchAttributeOrRelationship{attribute_or_relationship: :other}] =
               Keyword.get(meta.errors, :filters)
    end
  end

  describe "validate!/1" do
    test "returns Pagify struct" do
      assert Pagify.validate!(Post, %Pagify{}) == %Pagify{
               limit: 15,
               offset: 0,
               scopes: %{status: :all}
             }

      assert Pagify.validate!(Post, %{}) == %Pagify{
               limit: 15,
               offset: 0,
               scopes: %{status: :all}
             }
    end

    test "raises if params are invalid" do
      error =
        assert_raise Pagify.Error.Query.InvalidParamsError, fn ->
          Pagify.validate!(Post, %{limit: -1, filters: %{name: "Post 1", other: "John"}})
        end

      assert %{limit: -1, filters: %{name: "Post 1", other: "John"}} == error.params

      assert [%Ash.Error.Query.InvalidLimit{limit: -1}] = Keyword.get(error.errors, :limit)

      assert [%Ash.Error.Query.NoSuchAttributeOrRelationship{attribute_or_relationship: :other}] =
               Keyword.get(error.errors, :filters)
    end
  end

  describe "get_index/2" do
    test "returns index of a field in the `Pagify.order_by` list" do
      order_by = [name: :asc, age: :desc]
      assert Pagify.get_index(order_by, :name) == 0
      assert Pagify.get_index(order_by, :age) == 1
      assert Pagify.get_index(order_by, :species) == nil

      # Or with a list of strings
      order_by = ["name", "age"]
      assert Pagify.get_index(order_by, :name) == 0
      assert Pagify.get_index(order_by, :age) == 1
      assert Pagify.get_index(order_by, :species) == nil

      # Or with a tuple:
      order_by = {:name, :asc}
      assert Pagify.get_index(order_by, :name) == nil
      assert Pagify.get_index(order_by, :age) == nil

      # Or with a single string:
      order_by = "name"
      assert Pagify.get_index(order_by, :name) == nil
      assert Pagify.get_index(order_by, :age) == nil

      # Or with a single atom:
      order_by = :name
      assert Pagify.get_index(order_by, :name) == nil
      assert Pagify.get_index(order_by, :age) == nil

      # If the `order_by` parameter is `nil`, the function will return `nil`.
      assert Pagify.get_index(nil, :name) == nil
    end
  end

  describe "push_order/3" do
    test "raises error if invalid directions option is passed" do
      for pagify <- [%Pagify{}, %Pagify{order_by: [:name]}],
          directions <- [{:up, :down}, "up,down"] do
        assert_raise Pagify.Error.Query.InvalidDirectionsError, fn ->
          Pagify.push_order(pagify, :name, directions: directions)
        end
      end
    end
  end

  describe "get_option/3" do
    test "returns value from option list" do
      # sanity check
      default_limit = Post.default_limit()
      assert default_limit && default_limit != 40

      assert Pagify.get_option(
               :default_limit,
               [default_limit: 40, for: Post],
               1
             ) == 40
    end

    test "falls back to resource option" do
      # sanity check
      assert default_limit = Post.default_limit()

      assert Pagify.get_option(
               :default_limit,
               [for: Post],
               1
             ) == default_limit
    end

    test "falls back to default Pagify value" do
      assert Pagify.get_option(:default_limit, []) == 25
    end

    test "falls back to default value passed to function" do
      assert Pagify.get_option(:some_option, [], 2) == 2
    end

    test "falls back to nil" do
      assert Pagify.get_option(:some_option, []) == nil
    end

    test "merges pagify_scopes" do
      # sanity check
      assert Pagify.get_option(:pagify_scopes, [for: Post], %{}) == Post.pagify_scopes()

      # with default value
      assert Pagify.get_option(:pagify_scopes, [for: Post], %{
               role: [
                 %{name: :admin, filter: %{author: "John"}, default?: true}
               ]
             }) == %{
               role: [
                 %{name: :admin, filter: %{author: "John"}, default?: true},
                 %{name: :user, filter: %{author: "Doe"}}
               ],
               status: [
                 %{name: :all, filter: nil, default?: true},
                 %{name: :active, filter: %{age: %{lt: 10}}},
                 %{name: :inactive, filter: %{age: %{gte: 10}}}
               ]
             }

      # with opts scopes
      opts = [
        pagify_scopes: %{
          other: [
            %{name: :other, filter: %{name: "other"}}
          ],
          role: [
            %{name: :user, filter: %{name: "changed"}},
            %{name: :other, filter: %{name: "other"}}
          ],
          status: [
            %{name: :inactive, filter: %{age: %{gte: 10}}},
            %{name: :all, filter: nil, default?: true},
            %{name: :active, filter: %{age: %{lt: 10}}}
          ]
        },
        for: Post
      ]

      default = %{
        role: [
          %{name: :admin, filter: %{author: "John"}, default?: true}
        ]
      }

      assert Pagify.get_option(:pagify_scopes, opts, default) == %{
               role: [
                 %{name: :admin, filter: %{author: "John"}, default?: true},
                 %{name: :user, filter: %{name: "changed"}},
                 %{name: :other, filter: %{name: "other"}}
               ],
               other: [
                 %{name: :other, filter: %{name: "other"}}
               ],
               status: [
                 %{name: :inactive, filter: %{age: %{gte: 10}}},
                 %{name: :all, filter: nil, default?: true},
                 %{name: :active, filter: %{age: %{lt: 10}}}
               ]
             }
    end
  end

  describe "query_to_filters_map/2" do
    test "compiles scopes into filters" do
      assert %Pagify{
               filters: %{"and" => [%{"author" => "John"}]},
               scopes: [role: :admin]
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 scopes: [{:role, :admin}]
               })
    end

    test "compiles filter_form into filters" do
      assert %Pagify{
               filters: %{"and" => [%{"name" => %{"eq" => "Post 1"}}]},
               filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"}
               })
    end

    test "compiles filters into filters" do
      assert %Pagify{
               filters: %{"and" => [%{"author" => "Author 1"}]}
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filters: %{author: "Author 1"}
               })
    end

    test "accounts for and base filter" do
      assert %Pagify{
               filters: %{"and" => [%{"author" => "Author 1"}]}
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filters: %{"and" => [%{author: "Author 1"}]}
               })
    end

    test "accounts for or base filter" do
      assert %Pagify{
               filters: %{"or" => [%{"author" => "Author 1"}]}
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filters: %{"or" => [%{author: "Author 1"}]}
               })
    end

    test "merges filters from scope, filter_form, and filters into filters" do
      assert %Pagify{
               filters: %{
                 "and" => [
                   %{"comments_count" => %{"gt" => 2}},
                   %{"name" => %{"eq" => "Post 1"}},
                   %{"author" => "John"}
                 ]
               },
               filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
               scopes: [role: :admin]
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
                 scopes: [{:role, :admin}],
                 filters: %{comments_count: %{gt: 2}}
               })
    end

    test "filter_form overrides filters" do
      assert %Pagify{
               filters: %{
                 "and" => [
                   %{"name" => %{"eq" => "Post 2"}}
                 ]
               },
               filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 2"}
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 2"},
                 filters: %{"and" => %{"name" => "Post 1"}}
               })
    end

    test "stores full-text search under __full_text_search" do
      assert %Pagify{
               filters: %{
                 "__full_text_search" => "Post 1"
               },
               search: "Post 1"
             } ==
               Pagify.query_to_filters_map(
                 Post,
                 %Pagify{
                   search: "Post 1"
                 }
               )
    end

    test "stores full-text search under __full_text_search in combinatino with other filters" do
      assert %Pagify{
               filters: %{
                 "and" => [
                   %{"comments_count" => %{"gt" => 2}},
                   %{"name" => %{"eq" => "Post 1"}},
                   %{"author" => "John"}
                 ],
                 "__full_text_search" => "Post 1"
               },
               filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
               scopes: [role: :admin],
               search: "Post 1"
             } ==
               Pagify.query_to_filters_map(
                 Post,
                 %Pagify{
                   filter_form: %{"field" => "name", "operator" => "eq", "value" => "Post 1"},
                   scopes: [{:role, :admin}],
                   filters: %{comments_count: %{gt: 2}},
                   search: "Post 1"
                 }
               )
    end

    test "does not store full-text search under __full_text_search if disabled" do
      assert %Pagify{
               filters: %{},
               search: "Post 1"
             } ==
               Pagify.query_to_filters_map(
                 Post,
                 %Pagify{
                   search: "Post 1"
                 },
                 include_full_text_search?: false
               )
    end

    test "does not raise and not store in case of invalid full-text search" do
      assert %{
               filters: %{},
               search: "Comment 1",
               errors: [
                 search: [
                   %Pagify.Error.Query.SearchNotImplemented{resource: Pagify.Factory.Comment}
                 ]
               ]
             } =
               Pagify.query_to_filters_map(
                 Comment,
                 %Pagify{
                   search: "Comment 1"
                 },
                 raise_on_invalid_search?: false
               )
    end

    test "raises and does not store in case of invalid full-text search" do
      assert_raise Pagify.Error.Query.SearchNotImplemented, fn ->
        Pagify.query_to_filters_map(
          Comment,
          %Pagify{
            search: "Comment 1"
          }
        )
      end
    end

    test "scope overrides filters" do
      assert %Pagify{
               filters: %{
                 "and" => [
                   %{"author" => "John"}
                 ]
               },
               scopes: [role: :admin]
             } ==
               Pagify.query_to_filters_map(Post, %Pagify{
                 filters: %{"author" => "Author 1"},
                 scopes: [{:role, :admin}]
               })
    end
  end

  describe "query_for_filters_map/2" do
    test "converts compiled filters to map" do
      assert Pagify.query_for_filters_map(Post, %{"and" => [%{"name" => "foo"}]}) ==
               Ash.Query.filter(Post, %{name: "foo"})
    end

    test "does not include full_text_search if disabled" do
      assert Pagify.query_for_filters_map(
               Post,
               %{"and" => [%{"name" => "foo"}], "__full_text_search" => "bar"},
               include_full_text_search?: false
             ) ==
               Ash.Query.filter(Post, %{name: "foo"})
    end

    test "includes full_text_search per default" do
      assert Pagify.query_for_filters_map(
               Post,
               %{"__full_text_search" => "bar"}
             ) ==
               Ash.Query.filter(
                 Post,
                 full_text_search(search: Ash.Query.expr(tsquery(search: "bar")))
               )
    end

    test "does not include full_text_search if include_full_text_search? is true but none is provided" do
      assert Pagify.query_for_filters_map(
               Post,
               %{"name" => "bar"}
             ) ==
               Ash.Query.filter(
                 Post,
                 name: "bar"
               )
    end

    test "does not include full_text_search if none is configured and does not raise" do
      assert Pagify.query_for_filters_map(
               Comment,
               %{"and" => [%{"body" => "foo"}], "__full_text_search" => "bar"},
               raise_on_invalid_search?: false
             ) ==
               Ash.Query.filter(Comment, %{body: "foo"})
    end

    test "does not include full_text_search if none is configured and raises" do
      assert_raise Pagify.Error.Query.SearchNotImplemented, fn ->
        Pagify.query_for_filters_map(
          Comment,
          %{"and" => [%{"body" => "foo"}], "__full_text_search" => "bar"}
        )
      end
    end
  end

  defp assert_post_names(pagify, names, opts \\ []) do
    %Ash.Page.Offset{results: posts} = Pagify.all(Post, pagify, opts)

    assert Enum.map(posts, & &1.name) == names
  end

  defp assert_page_opts(pagify, expected, opts) do
    %Ash.Page.Offset{rerun: {_, opts}} = Pagify.all(Post, pagify, opts)

    page = Keyword.get(opts, :page, [])
    assert_lists_equal(expected, page)
  end

  defp assert_comment_names(pagify, names, opts \\ []) do
    %Ash.Page.Offset{results: comments} = Pagify.all(Comment, pagify, opts)

    assert Enum.map(comments, & &1.body) == names
  end

  defp assert_comment_page_opts(pagify, expected, opts) do
    %Ash.Page.Offset{rerun: {_, opts}} = Pagify.all(Comment, pagify, opts)

    page = Keyword.get(opts, :page, [])
    assert_lists_equal(expected, page)
  end
end
