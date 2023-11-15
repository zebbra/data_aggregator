defmodule DataAggregatorWeb.Components.Header do
  @moduledoc """
  Renders a header with title.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Headless.Dialog, only: [dialog_title: 1]

  @doc ~S"""
  Renders a header with title.
  """
  attr :class, :string, default: nil, doc: "the header class"
  attr :action_class, :string, default: "flex gap-x-3"

  attr :id, :string, default: nil

  attr :title_size, :string,
    default: "text-2xl",
    values: ["text-2xl", "text-xl", "text-lg", "text-base", "text-sm"],
    doc: "the size of the title"

  attr :dialog_header_id, :string,
    default: nil,
    doc: "if set we assume a dialog header and use the dialog_header component"

  slot :inner_block, required: true
  slot :subtitle, doc: "the optional subtitle displayed below the title"
  slot :actions, doc: "the optional actions displayed on the right side of the header"

  def header(assigns) do
    ~H"""
    <header class={[
      "dark:bg-gray-900 z-10 bg-white border-b dark:border-white/5 border-gray-200 p-4 sm:py-5 sm:px-6 lg:px-8 w-full",
      @actions != [] &&
        "flex items-center justify-between gap-6",
      @class
    ]}>
      <div>
        <.dialog_title
          :if={@dialog_header_id}
          id={@dialog_header_id <> "__title"}
          class={[
            "dark:text-white font-semibold leading-9 text-gray-800",
            @title_size
          ]}
        >
          <%= render_slot(@inner_block) %>
        </.dialog_title>
        <h1
          :if={!@dialog_header_id}
          class={[
            "dark:text-white font-semibold leading-9 text-gray-800 outline-none",
            @title_size
          ]}
        >
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="dark:text-gray-400 mt-2 text-sm leading-6 text-gray-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class={@action_class}><%= render_slot(@actions) %></div>
    </header>
    """
  end
end
