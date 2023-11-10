defmodule DataAggregatorWeb.ViewportHelpers do
  @moduledoc """
  ViewportHelpers

  This module is used to provide a macro that can be used to import the
  `handle_event` function into a LiveView. This function will be called
  whenever the browser window is resized. The function will receive the
  new width of the browser window as a string.

  ## Usage

  ```elixir
  defmodule DataAggregatorWeb.Live.Dashboard do
    use DataAggregatorWeb, :live_view
    use DataAggregatorWeb.ViewportHelpers
  end
  ```

  ```html
  <.page id="page-id" phx-hook="ViewportResize>
    <%= display_size(@viewport_width) %>
  </.page>
  ```
  """
  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.ViewportHelpers

      @sm 640
      @md 768
      @lg 1024
      @xl 1280
      @xxl 1536

      @display_sm :display_sm
      @display_md :display_md
      @display_lg :display_lg
      @display_xl :display_xl
      @display_xxl :display_xxl

      @doc """
      Returns the display size based on the width of the browser window.

      ## Examples

      ```elixir
      display_size(@viewport_width)
      ```
      """
      def display_size(width) when width < @md, do: @display_sm
      def display_size(width) when width < @lg, do: @display_md
      def display_size(width) when width < @xl, do: @display_lg
      def display_size(width) when width < @xxl, do: @display_xl
      def display_size(width), do: @display_xxl

      @doc """
      Returns true if the width of the browser window is equal or greater to the
      specified width. Same behaviour as tailwindcss breakpoint classes.

      ## Examples

      ```elixir
      display_size_sm(@viewport_width)
      ```
      """
      def display_size_sm(width) when width >= @sm, do: true
      def display_size_sm(width), do: false

      def display_size_md(width) when width >= @md, do: true
      def display_size_md(width), do: false

      def display_size_lg(width) when width >= @lg, do: true
      def display_size_lg(width), do: false

      def display_size_xl(width) when width >= @xl, do: true
      def display_size_xl(width), do: false

      def display_size_xxl(width) when width >= @xxl, do: true
      def display_size_xxl(width), do: false

      @doc """
      Returns true if the width of the browser window is less than the
      specified width and the display size is equal to the specified
      display size.

      ## Examples

      ```elixir
      display_size_lt(@viewport_width, :display_sm)
      ```
      """
      def display_size_lt(width, size) when width < @md and size == @display_md, do: true
      def display_size_lt(width, size) when width < @lg and size == @display_lg, do: true
      def display_size_lt(width, size) when width < @xl and size == @display_xl, do: true
      def display_size_lt(width, size) when width < @xxl and size == @display_xxl, do: true
      def display_size_lt(width, size), do: false

      @doc """
      Returns true if the width of the browser window is greater than the
      specified width and the display size is equal to the specified
      display size.

      ## Examples

      ```elixir
      display_size_gt(@viewport_width, :display_sm)
      ```
      """
      def display_size_gt(width, size) when width >= @md and size == @display_sm, do: true
      def display_size_gt(width, size) when width >= @lg and size == @display_md, do: true
      def display_size_gt(width, size) when width >= @xl and size == @display_lg, do: true
      def display_size_gt(width, size) when width >= @xxl and size == @display_xl, do: true
      def display_size_gt(width, size), do: false

      @doc """
      Resize handler to assign new viewport width to socket.
      """
      def handle_event("viewport_resize", %{"width" => width} = viewport, socket) do
        {:noreply, assign(socket, :viewport_width, width)}
      end
    end
  end
end
