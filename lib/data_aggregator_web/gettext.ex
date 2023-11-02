defmodule DataAggregatorWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import DataAggregatorWeb.Gettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # Domain-based translation
      dgettext("errors", "Here is the error message to translate")

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :data_aggregator

  @doc ~S"""
  Returns all the locales for which PO files exist for the given `backend`.
  """
  def known_locales do
    Gettext.known_locales(__MODULE__)
  end

  @doc ~S"""
  Gets the current Gettext locale for the current process.
  """
  def get_locale do
    Gettext.get_locale(__MODULE__)
  end

  @doc ~S"""
   Sets the current Gettext locale for the current process.
  """
  def put_locale(locale) do
    Gettext.put_locale(__MODULE__, locale)
  end

  def default_locale do
    Application.get_env(:data_aggregator, __MODULE__)
    |> Keyword.get(:default_locale)
  end

  def with_locale(locale, fun) do
    Gettext.with_locale(__MODULE__, locale, fun)
  end

  def with_default_locale(fun) do
    default_locale() |> with_locale(fun)
  end

  defmacro mgettext(text, opts \\ []) do
    context = inspect(__CALLER__.module)

    quote do
      pgettext(unquote(context), unquote(text), unquote(opts))
    end
  end

  defmacro sigil_t({:<<>>, _, [text]}, []) do
    quote do
      gettext(unquote(text))
    end
  end

  defmacro sigil_t({:<<>>, _, [text]}, [?m]) do
    quote do
      mgettext(unquote(text))
    end
  end

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      require unquote(__MODULE__)
    end
  end
end
