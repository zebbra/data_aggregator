defmodule Pagify.Tsearch do
  @moduledoc false

  alias Pagify.Misc

  require Ash.Query

  @disallowed_tsquery_characters ~r/['?\\:‘’ʻʼ\|\&]/u

  @typedoc """
  A list of options for full text search.

  - `:negation` - Whether to negate the search. Defaults to `true`.
  - `:prefix` - Whether to prefix the search. Defaults to `true`.
  - `:any_word` - Whether to combine multiple words with || or &&. Defaults to `false` (&&).
  - `:tsvector_column` - Custom tsvector column expressions for dynamic tsvector
    column lookup. Defaults to `nil`.
  """
  @type tsearch_option ::
          {:negation, boolean()}
          | {:prefix, boolean()}
          | {:any_word, boolean()}
          | {:tsvector_column, Ash.Expr.t() | list(Ash.Expr.t())}

  @spec default_opts() :: [tsearch_option()]
  def default_opts do
    [
      negation: true,
      prefix: true,
      any_word: false,
      tsvector_column: nil
    ]
  end

  @dynamic_opts [:search, :tsvector, :tsvector_column]

  def option_keys do
    Enum.map(default_opts(), &elem(&1, 0)) ++ @dynamic_opts
  end

  def merge_opts(opts \\ []) do
    default_opts()
    |> Misc.list_merge(Misc.get_global_opts(:full_text_search, :pagify))
    |> Misc.list_merge(resource_option(Keyword.get(opts, :for)))
    |> Misc.list_merge(Keyword.get(opts, :full_text_search, []))
  end

  defp resource_option(resource) when is_atom(resource) and resource != nil do
    if Keyword.has_key?(resource.__info__(:functions), :full_text_search) do
      resource.full_text_search()
    else
      []
    end
  end

  defp resource_option(_), do: []

  def tsvector(opts \\ []) do
    full_text_search = merge_opts(opts)

    tsvector = Keyword.get(full_text_search, :tsvector)
    tsvector_column = Keyword.get(full_text_search, :tsvector_column)

    coalesce_tsvector(tsvector, tsvector_column)
  end

  defp coalesce_tsvector(nil, nil), do: Ash.Query.expr(tsvector)
  defp coalesce_tsvector(_, nil), do: Ash.Query.expr(tsvector)

  defp coalesce_tsvector(key, tsvector_column) when is_binary(key) and is_list(tsvector_column) do
    coalesce_tsvector(String.to_existing_atom(key), tsvector_column)
  end

  defp coalesce_tsvector(key, tsvector_column) when is_atom(key) and is_list(tsvector_column) do
    Keyword.get(tsvector_column, key, Ash.Query.expr(tsvector))
  end

  defp coalesce_tsvector(nil, tsvector_column) do
    if is_tuple(tsvector_column) or is_list(tsvector_column) do
      Ash.Query.expr(tsvector)
    else
      tsvector_column
    end
  end

  defp coalesce_tsvector(_, _), do: Ash.Query.expr(tsvector)

  def tsquery(search, opts \\ [])
  def tsquery("", _opts), do: "''"
  def tsquery(nil, _opts), do: "''"

  def tsquery(search, opts) do
    opts = merge_opts(opts)

    tsquery_terms =
      search
      |> query_terms()
      |> Enum.map(&tsquery_for_term(&1, opts))
      |> Enum.reject(&blank?/1)

    if Keyword.get(opts, :any_word, false) do
      Enum.join(tsquery_terms, " | ")
    else
      Enum.join(tsquery_terms, " & ")
    end
  end

  def query_terms(search) do
    search
    |> String.split(~r/\s+/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&blank?/1)
  end

  def tsquery_for_term(unsanitized_term, opts \\ []) do
    {negated, sanitized_term} =
      sanitize_term(unsanitized_term, Keyword.get(opts, :negation, false))

    term_sql = normalize(sanitized_term)

    if String.trim(term_sql) == "" do
      ""
    else
      prefix = Keyword.get(opts, :prefix, false)
      tsquery_expression(term_sql, negated: negated, prefix: prefix)
    end
  end

  def sanitize_term(term, true) do
    negated = String.starts_with?(term, "!")
    term = if negated, do: String.replace_prefix(term, "!", ""), else: term

    {negated, term}
  end

  def sanitize_term(term, false), do: {false, term}

  def normalize(term) do
    String.replace(term, @disallowed_tsquery_characters, " ")
  end

  @doc """
  After this, the SQL expression evaluates to a string containing the term surrounded by single-quotes.

  If :prefix is true, then the term will have :* appended to the end.
  If :negated is true, then the term will have ! prepended to the front and be surrounded by brackets.
  """
  def tsquery_expression(term_sql, opts \\ []) do
    negated = Keyword.get(opts, :negated, false)
    prefix = Keyword.get(opts, :prefix, false)

    [
      if(negated, do: "!("),
      term_sql,
      if(prefix, do: ":*"),
      if(negated, do: ")")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join()
  end

  defp blank?(t), do: String.trim(t) == ""

  defmacro __using__(opts \\ []) do
    require Ash.Query

    only = Keyword.get(opts, :only, [])

    quote do
      if unquote(only) == [] or :full_text_search in unquote(only) do
        calculations do
          calculate :full_text_search,
                    :boolean,
                    expr(fragment("(? @@ ?)", ^arg(:tsvector), ^arg(:tsquery))) do
            argument :tsvector, AshPostgres.Tsvector, allow_expr?: true, allow_nil?: false
            argument :tsquery, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
          end
        end
      end

      if unquote(only) == [] or :full_text_search_rank in unquote(only) do
        calculations do
          calculate :full_text_search_rank,
                    :float,
                    expr(fragment("ts_rank(?, ?)", ^arg(:tsvector), ^arg(:tsquery))) do
            argument :tsvector, AshPostgres.Tsvector, allow_expr?: true, allow_nil?: false
            argument :tsquery, AshPostgres.Tsquery, allow_expr?: true, allow_nil?: false
          end
        end
      end

      if unquote(only) == [] or :tsquery in unquote(only) do
        calculations do
          calculate :tsquery,
                    AshPostgres.Tsquery,
                    expr(fragment("to_tsquery('simple', ?)", ^arg(:search))) do
            argument :search, :string, allow_expr?: true, allow_nil?: false
          end
        end
      end
    end
  end
end
