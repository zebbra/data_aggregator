defmodule Pagify.ValidationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Pagify.Factory

  alias Pagify.Factory.Comment
  alias Pagify.Factory.Post
  alias Pagify.Validation

  doctest Pagify.Validation, import: true

  test "passes with empty params and resource" do
    assert {:ok, %Pagify{limit: 15, offset: 0}} = Validation.validate_params(Post, %{})
  end

  test "passes with empty params and query" do
    assert {:ok, %Pagify{limit: 15, offset: 0}} =
             Validation.validate_params(Ash.Query.new(Post), %{})
  end

  test "does not set limit if default_limit is set to false" do
    assert {:ok, %Pagify{limit: nil, offset: 0}} =
             Validation.validate_params(Post, %{}, default_limit: false)
  end

  test "detects all errors and validates params" do
    {:error, errors, validated_params} =
      Validation.validate_params(Post, %{limit: -1, offset: -1, filters: 1, order_by: 1}, replace_invalid_params?: true)

    assert [
             offset: [%Ash.Error.Query.InvalidOffset{offset: -1}],
             limit: [%Ash.Error.Query.InvalidLimit{limit: -1}],
             order_by: [%Pagify.Error.Query.InvalidOrderByParameter{order_by: 1}],
             filters: [%Ash.Error.Query.InvalidFilterValue{value: 1}]
           ] = errors

    assert %{limit: 15, offset: 0, filters: nil, order_by: nil} = validated_params
  end

  test "detects all errors and keeps original params" do
    params = %{limit: -1, offset: -1, filters: 1, order_by: 1}

    {:error, errors, original_params} =
      Validation.validate_params(Post, params)

    assert [
             offset: [%Ash.Error.Query.InvalidOffset{offset: -1}],
             limit: [%Ash.Error.Query.InvalidLimit{limit: -1}],
             order_by: [%Pagify.Error.Query.InvalidOrderByParameter{order_by: 1}],
             filters: [%Ash.Error.Query.InvalidFilterValue{value: 1}]
           ] = errors

    assert %{limit: -1, offset: -1, filters: 1, order_by: 1} = original_params
  end

  test "passes with string based map params" do
    assert {:ok, %Pagify{limit: 15, offset: 0, order_by: [name: :asc], scopes: %{role: :admin}}} =
             Validation.validate_params(Post, %{
               "limit" => "15",
               "offset" => "0",
               "filters" => %{author: "John"},
               "order_by" => "name",
               "scopes" => %{"role" => "admin"}
             })
  end

  describe "validate_scopes/2" do
    test "passes with nil scopes" do
      assert %{scopes: nil} = Validation.validate_scopes(%{scopes: nil}, %{})
    end

    test "passes with no scopes" do
      assert %{} = Validation.validate_scopes(%{}, %{})
    end

    test "passes with empty map scopes" do
      assert %{scopes: nil} = Validation.validate_scopes(%{scopes: %{}}, %{})
    end

    test "passes with non-empty map scopes" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{scopes: %{role: :admin}} =
               Validation.validate_scopes(%{scopes: %{role: :admin}}, pagify_scopes)
    end

    test "replaces invalid scope name and adds errors" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: nil,
               errors: [
                 scopes: [%Pagify.Error.Query.NoSuchScope{group: :role, name: :invalid}]
               ]
             } =
               Validation.validate_scopes(%{scopes: %{role: :invalid}}, pagify_scopes, nil, true)
    end

    test "does not replace invalid scope name and adds errors" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: %{role: :invalid},
               errors: [
                 scopes: [%Pagify.Error.Query.NoSuchScope{group: :role, name: :invalid}]
               ]
             } =
               Validation.validate_scopes(%{scopes: %{role: :invalid}}, pagify_scopes)
    end

    test "replaces invalid scope group and adds errors" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: nil,
               errors: [
                 scopes: [%Pagify.Error.Query.NoSuchScope{group: :invalid, name: :admin}]
               ]
             } =
               Validation.validate_scopes(%{scopes: %{invalid: :admin}}, pagify_scopes, nil, true)
    end

    test "does not replace invalid scope group and adds errors" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: %{invalid: :admin},
               errors: [
                 scopes: [%Pagify.Error.Query.NoSuchScope{group: :invalid, name: :admin}]
               ]
             } =
               Validation.validate_scopes(%{scopes: %{invalid: :admin}}, pagify_scopes)
    end

    test "replaces invalid scopes parameter" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: nil,
               errors: [
                 scopes: [%Pagify.Error.Query.InvalidScopesParameter{scopes: 1}]
               ]
             } =
               Validation.validate_scopes(%{scopes: 1}, pagify_scopes, nil, true)
    end

    test "does not replace invalid scopes parameter" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: 1,
               errors: [
                 scopes: [%Pagify.Error.Query.InvalidScopesParameter{scopes: 1}]
               ]
             } =
               Validation.validate_scopes(%{scopes: 1}, pagify_scopes)
    end

    test "replaces invalid scope group and keeps valid scopes" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: %{role: :admin},
               errors: [
                 scopes: [%Pagify.Error.Query.NoSuchScope{group: :invalid, name: :admin}]
               ]
             } =
               Validation.validate_scopes(
                 %{scopes: %{role: :admin, invalid: :admin}},
                 pagify_scopes,
                 nil,
                 true
               )
    end

    test "replaces invalid scope group and keeps valid scopes and loads default scopes" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{
               scopes: %{role: :user},
               errors: [
                 scopes: [%Pagify.Error.Query.NoSuchScope{group: :invalid, name: :admin}]
               ]
             } =
               Validation.validate_scopes(
                 %{scopes: %{invalid: :admin}},
                 pagify_scopes,
                 %{role: :user},
                 true
               )
    end

    test "loads default scopes" do
      pagify_scopes = Pagify.get_option(:pagify_scopes, for: Post)

      assert %{scopes: %{role: :user}} =
               Validation.validate_scopes(%{}, pagify_scopes, %{role: :user})
    end
  end

  describe "validate_filter_form/2" do
    test "passes with nil filter_form" do
      params = Validation.validate_filter_form(%{filter_form: nil}, Post)
      assert %{filter_form: nil} = params
      refute Map.has_key?(params, :errors)
    end

    test "passes with no filter_form" do
      assert %{} == Validation.validate_filter_form(%{}, Post)
    end

    test "passes with empty map filter_form" do
      params = Validation.validate_filter_form(%{filter_form: %{}}, Post)
      assert %{filter_form: %{}} = params
      refute Map.has_key?(params, :errors)
    end

    test "passes with non-empty map filter_form" do
      filter_form_params = build(:form_filter_parameter)

      params = Validation.validate_filter_form(%{filter_form: filter_form_params}, Post)
      assert %{filter_form: ^filter_form_params} = params
      refute Map.has_key?(params, :errors)
    end

    test "passes with relational filter_form" do
      filter_form_params = build(:relational_filter_form_parameter)

      params = Validation.validate_filter_form(%{filter_form: filter_form_params}, Post)
      assert %{filter_form: ^filter_form_params} = params
      refute Map.has_key?(params, :errors)
    end

    test "passes with calculated filter_form" do
      filter_form_params = build(:calculated_filter_form_parameter)

      params = Validation.validate_filter_form(%{filter_form: filter_form_params}, Post)
      assert %{filter_form: ^filter_form_params} = params
      refute Map.has_key?(params, :errors)
    end

    test "replaces simple invalid filter_form fields and adds errors" do
      filter_form_params = build(:invalid_filter_form_parameter)

      assert %{
               :filter_form => %{},
               :errors => [filter_form: [field: {"No such field invalid_field", []}]]
             } =
               Validation.validate_filter_form(%{filter_form: filter_form_params}, Post, true)
    end

    test "does not replace simple invalid filter_form fields and adds errors" do
      filter_form_params = build(:invalid_filter_form_parameter)

      assert %{
               :filter_form => ^filter_form_params,
               :errors => [filter_form: [field: {"No such field invalid_field", []}]]
             } =
               Validation.validate_filter_form(%{filter_form: filter_form_params}, Post)
    end

    test "replaces complex invalid filter_form and adds errors and keeps valid fields" do
      filter_form_params = build(:complex_invalid_filter_form_parameter)

      assert %{
               :filter_form => %{
                 "components" => %{
                   "0" => %{
                     "field" => :name,
                     "negated?" => false,
                     "operator" => :eq,
                     "path" => "",
                     "value" => "Post 1"
                   }
                 },
                 "negated" => "false",
                 "operator" => "or"
               },
               :errors => [filter_form: [field: {"No such field invalid_field", []}]]
             } =
               Validation.validate_filter_form(
                 %{filter_form: filter_form_params},
                 Post,
                 true
               )
    end
  end

  describe "validate_filters/2" do
    test "passes with nil filters" do
      assert %{filters: nil} = Validation.validate_filters(%{filters: nil}, Post)
    end

    test "passes with no filters" do
      assert %{} = Validation.validate_filters(%{}, Post)
    end

    test "passes with empty list filters" do
      assert %{filters: %Ash.Filter{}} = Validation.validate_filters(%{filters: []}, Post)
    end

    test "passes non-empty list filters" do
      assert %{filters: %Ash.Filter{}} =
               Validation.validate_filters(%{filters: [%{name: "Post 1"}]}, Post)
    end

    test "passes with empty map filters" do
      assert %{filters: %Ash.Filter{}} = Validation.validate_filters(%{filters: %{}}, Post)
    end

    test "passes with non-empty map filters" do
      assert %{filters: %Ash.Filter{}} =
               Validation.validate_filters(%{filters: %{name: "Post 1"}}, Post)
    end

    test "passes with relational filters" do
      assert %{filters: %Ash.Filter{}} =
               Validation.validate_filters(%{filters: %{comments: %{body: "Test"}}}, Post)
    end

    test "passes with calculated filters" do
      assert %{filters: %Ash.Filter{}} =
               Validation.validate_filters(%{filters: %{comments_count: %{gt: 1}}}, Post)
    end

    test "replaces simple invalid filters and adds errors" do
      assert %{:filters => nil, :errors => [filters: [%Ash.Error.Query.InvalidFilterValue{}]]} =
               Validation.validate_filters(%{filters: 1}, Post, true)
    end

    test "does not replace simple invalid filters and adds errors" do
      assert %{:filters => 1, :errors => [filters: [%Ash.Error.Query.InvalidFilterValue{}]]} =
               Validation.validate_filters(%{filters: 1}, Post)
    end

    test "replaces complex invalid filters and adds errors" do
      assert %{
               :filters => nil,
               :errors => [
                 filters: [
                   %Ash.Error.Query.NoSuchField{},
                   %Ash.Error.Query.NoSuchField{}
                 ]
               ]
             } =
               Validation.validate_filters(
                 %{filters: %{and: [%{invalid_attribute_1: 1, invalid_attribute_2: 2}]}},
                 Post,
                 true
               )
    end

    test "replaces complex invalid filters and adds errors and keeps valid filters" do
      assert %{
               :filters => %Ash.Filter{},
               :errors => [
                 filters: [
                   %Ash.Error.Query.NoSuchField{},
                   %Ash.Error.Query.NoSuchField{}
                 ]
               ]
             } =
               Validation.validate_filters(
                 %{filters: %{name: "Post 1", invalid_attribute_1: 1, invalid_attribute_2: 2}},
                 Post,
                 true
               )
    end
  end

  describe "validate_order_by/2" do
    test "passes with nil order_by" do
      assert %{order_by: nil} = Validation.validate_order_by(%{order_by: nil}, Post)
    end

    test "passes with no order_by" do
      assert %{} = Validation.validate_order_by(%{}, Post)
    end

    test "passes with empty list order_by" do
      assert %{order_by: []} = Validation.validate_order_by(%{order_by: []}, Post)
    end

    test "passes with non-empty list order_by" do
      assert %{order_by: [name: :asc]} =
               Validation.validate_order_by(%{order_by: ["name"]}, Post)
    end

    test "passes with single string" do
      assert %{order_by: [name: :asc]} =
               Validation.validate_order_by(%{order_by: "name"}, Post)
    end

    test "passes with single string and direction" do
      assert %{order_by: [name: :desc]} =
               Validation.validate_order_by(%{order_by: "-name"}, Post)
    end

    test "passes with multiple strings" do
      assert %{order_by: [name: :asc, id: :desc]} =
               Validation.validate_order_by(%{order_by: ["name", "-id"]}, Post)
    end

    test "passes with multiple strings and directions" do
      assert %{order_by: [name: :asc_nils_first, id: :desc_nils_last]} =
               Validation.validate_order_by(%{order_by: "++name,--id"}, Post)
    end

    test "does not replace map order_by and adds errors" do
      assert %{
               order_by: %{name: :asc},
               errors: [
                 order_by: [
                   %Pagify.Error.Query.InvalidOrderByParameter{}
                 ]
               ]
             } =
               Validation.validate_order_by(%{order_by: %{name: :asc}}, Post)
    end

    test "replaces map order_by and adds errors" do
      assert %{
               order_by: nil,
               errors: [
                 order_by: [%Pagify.Error.Query.InvalidOrderByParameter{}]
               ]
             } =
               Validation.validate_order_by(%{order_by: %{name: :asc}}, Post, true)
    end

    test "passes with calculated order_by" do
      assert %{order_by: [comments_count: :asc]} =
               Validation.validate_order_by(%{order_by: "comments_count"}, Post)
    end

    test "replaces invalid order_by and adds errors" do
      assert %{
               order_by: [name: :desc_nils_last],
               errors: [
                 order_by: [
                   %Ash.Error.Query.NoSuchField{field: "non_existent", resource: Post}
                 ]
               ]
             } =
               Validation.validate_order_by(%{order_by: "--name,non_existent"}, Post, true)
    end
  end

  describe "validate_pagination/2" do
    test "limit must be a positive integer" do
      params = %{limit: 0}

      assert %{
               limit: 0,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 0}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "limit must not be an empty string" do
      params = %{limit: ""}

      assert %{
               limit: "",
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: ""}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "limit must not contain non-number characters" do
      params = %{limit: "a"}

      assert %{
               limit: "a",
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: "a"}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "resets invalid limit to resource default_limit with replace_invalid_params?" do
      params = %{limit: 0}

      assert %{
               limit: 15,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 0}]]
             } = Validation.validate_pagination(params, Post, true)
    end

    test "resets invalid limit to opts :default_limit with replace_invalid_params?" do
      params = %{limit: 0}

      assert %{
               limit: 10,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 0}]]
             } = Validation.validate_pagination(params, Comment, true, default_limit: 10)
    end

    test "resets invalid limit to Pagify.default_limit() with replace_invalid_params?" do
      params = %{limit: 0}

      assert %{
               limit: 25,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 0}]]
             } = Validation.validate_pagination(params, Comment, true)
    end

    test "offset must be a non-negative integer" do
      params = %{offset: -1}

      assert %{
               offset: -1,
               errors: [offset: [%Ash.Error.Query.InvalidOffset{offset: -1}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "offset must not be an empty string" do
      params = %{offset: ""}

      assert %{
               offset: "",
               errors: [offset: [%Ash.Error.Query.InvalidOffset{offset: ""}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "offset must not contain non-number characters" do
      params = %{offset: "a"}

      assert %{
               offset: "a",
               errors: [offset: [%Ash.Error.Query.InvalidOffset{offset: "a"}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "replaces invalid offset with replace_invalid_params?" do
      params = %{offset: -1}

      assert %{
               offset: 0,
               errors: [offset: [%Ash.Error.Query.InvalidOffset{offset: -1}]]
             } = Validation.validate_pagination(params, Post, true)
    end

    test "validates max limit" do
      params = %{limit: 101}

      assert %{
               limit: 101,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 101}]]
             } = Validation.validate_pagination(params, Post)
    end

    test "replaces invalid max limit with replace_invalid_params?" do
      params = %{limit: 101}

      assert %{
               limit: 15,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 101}]]
             } = Validation.validate_pagination(params, Post, true)
    end

    test "replaces invalid max limit with opts :default_limit with replace_invalid_params?" do
      params = %{limit: 101}

      assert %{
               limit: 10,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 101}]]
             } = Validation.validate_pagination(params, Comment, true, default_limit: 10)
    end

    test "replaces invalid max limit with Pagify.default_limit() with replace_invalid_params?" do
      params = %{limit: 101}

      assert %{
               limit: 25,
               errors: [limit: [%Ash.Error.Query.InvalidLimit{limit: 101}]]
             } = Validation.validate_pagination(params, Comment, true)
    end

    test "allows to overwrite max_limit with opts :max_limit" do
      params = %{limit: 101}

      assert %{limit: 101} =
               Validation.validate_pagination(params, Post, true, max_limit: 101)
    end

    test "does not set default limit if false" do
      params = %{}

      assert %{limit: 15} = Validation.validate_pagination(params, Post)

      assert %{limit: nil} =
               Validation.validate_pagination(params, Post, true, default_limit: false)
    end

    test "sets offset to 0 if limit is set without offset" do
      params = %{limit: 10}

      assert %{limit: 10, offset: 0} = Validation.validate_pagination(params, Post)
    end
  end
end
