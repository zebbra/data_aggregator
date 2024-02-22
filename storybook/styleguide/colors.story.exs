defmodule Storybook.Styleguide.Colors do
  @moduledoc false
  use PhoenixStorybook.Story, :page
  use Phoenix.Component

  @text [
    "text-base-content",
    "text-base-200",
    "text-base-300",
    "text-neutral",
    "text-primary",
    "text-secondary",
    "text-accent",
    "text-info",
    "text-success",
    "text-warning",
    "text-error"
  ]

  @text_bg [
    {"bg-base-100", "text-base-content"},
    {"bg-base-200", "text-base-content"},
    {"bg-base-300", "text-base-content"},
    {"bg-neutral", "text-neutral-content"},
    {"bg-primary", "text-primary-content"},
    {"bg-secondary", "text-secondary-content"},
    {"bg-accent", "text-accent-content"},
    {"bg-info", "text-info-content"},
    {"bg-success", "text-success-content"},
    {"bg-warning", "text-warning-content"},
    {"bg-error", "text-error-content"}
  ]

  @text_bg_trans [
    {"bg-base-100/10", "text-base-content"},
    {"bg-base-200/10", "text-base-content"},
    {"bg-base-300/10", "text-base-content"},
    {"bg-neutral/10", "text-neutral"},
    {"bg-primary/10", "text-primary"},
    {"bg-secondary/10", "text-secondary"},
    {"bg-accent/10", "text-accent"},
    {"bg-info/10", "text-info"},
    {"bg-success/10", "text-success"},
    {"bg-warning/10", "text-warning"},
    {"bg-error/10", "text-error"}
  ]

  @text_border [
    {"bg-base-100", "text-base-content", "border-base-content/10"},
    {"bg-base-200", "text-base-content", "border-base-content/20"},
    {"bg-base-300", "text-base-content", "border-base-content/30"},
    {"bg-neutral-content", "text-neutral", "border-neutral/20"},
    {"bg-primary-content", "text-primary", "border-primary/20"},
    {"bg-secondary-content", "text-secondary", "border-secondary/20"},
    {"bg-accent-content", "text-accent", "border-accent/20"},
    {"bg-info-content", "text-info", "border-info/20"},
    {"bg-success-content", "text-success", "border-success/20"},
    {"bg-warning-content", "text-warning", "border-warning/20"},
    {"bg-error-content", "text-error", "border-error/20"}
  ]

  attr :class, :string, required: false, default: nil
  slot :inner_block, required: true

  def preview(assigns) do
    ~H"""
    <div class={[
      "rounded-box bg-base-100 border-base-content/10 text-base-content not-prose grid gap-3 border p-6",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :text, :string, required: true
  attr :bg, :string, required: false, default: nil
  attr :border, :string, required: false, default: nil
  attr :class, :string, required: false, default: nil

  def color(assigns) do
    ~H"""
    <div class="flex items-center gap-4">
      <div class={[
        "size-12 flex items-center justify-center rounded text-center",
        @class,
        @text,
        @bg,
        @border
      ]}>
        <span class="text-sm font-semibold">TXT</span>
      </div>
      <div class="text-base-content/50 font-mono flex flex-col text-xs">
        <span><%= @text %></span>
        <span><%= @bg %></span>
        <span><%= @border %></span>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :subtitle, :string, required: false, default: nil

  def heading(assigns) do
    ~H"""
    <div class="mb-6">
      <h2 class="text-xl font-bold"><%= @title %></h2>
      <p :if={@subtitle} class="text-base-content/50"><%= @subtitle %></p>
    </div>
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :text, @text)
    assigns = assign(assigns, :text_bg, @text_bg)
    assigns = assign(assigns, :text_bg_trans, @text_bg_trans)
    assigns = assign(assigns, :text_border, @text_border)

    ~H"""
    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 md:grid-cols-2 xl:grid-cols-4">
      <div class="">
        <.heading title="Text" subtitle="without background" />
        <.preview>
          <.color :for={text <- @text} text={text} class="border border-base-300" />
        </.preview>
      </div>

      <div class="">
        <.heading title="Background" subtitle="without transparency" />
        <.preview>
          <.color :for={{bg, text} <- @text_bg} text={text} bg={bg} />
        </.preview>
      </div>

      <div class="">
        <.heading title="Background" subtitle="with 10% transparency" />
        <.preview>
          <.color :for={{bg, text} <- @text_bg_trans} text={text} bg={bg} />
        </.preview>
      </div>

      <div class="">
        <.heading title="Borders" subtitle="with inverted background/text" />
        <.preview>
          <.color
            :for={{bg, text, border} <- @text_border}
            text={text}
            bg={bg}
            border={border}
            class="border-2"
          />
        </.preview>
      </div>
    </div>
    """
  end
end
