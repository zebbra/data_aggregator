defmodule DataAggregatorWeb.Blocks.Slideover do
  @moduledoc """
  Slideover component.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Blocks.Header, only: [section_heading: 1]
  import DataAggregatorWeb.Components.Modal, only: [modal_header: 1, modal_footer: 1]
  import DataAggregatorWeb.Helpers, only: [class_names: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders a slideover with a title, subtitle, and actions.

  The slideover can be opened and closed with the `open` attribute.
  The `on_cancel` attribute is used to run JS commands when the slideover is closed.

  Pressing the `Escape` key will close the slideover.

  ## Example

  ```heex
  <.slideover
    title="Slideover Title"
    subtitle="Slideover Subtitle"
    open={@open}
    on_cancel={@on_cancel}
  >
    <p class="px-6 lg:px-8">
      This is the inner block of the slideover.
    </p>
    <:footer>
      <button type="button" class="btn btn-primary max-sm:btn-sm">Link</button>
    </:footer>
  </.slideover>
  ```
  """

  attr :id, :string, default: "slideover", doc: "the id of the slideover"
  attr :title, :string, required: true, doc: "the title of the slideover"
  attr :subtitle, :string, default: nil, doc: "the optional subtitle displayed below the title"
  attr :class, :string, default: "pt-6", doc: "the slideover class"
  attr :size, :string, default: "md", values: ~w[sm md lg xl], doc: "the slideover size"
  attr :gradient, :boolean, default: true, doc: "Whether to show a gradient below the title"

  attr :compact, :boolean,
    default: false,
    doc: "whether the slideover is compact (not min-h-dvh h-full) or not"

  attr :open, :boolean, default: false, doc: "whether the slideover is open or not"
  attr :left, :boolean, default: false, doc: "whether the slideover is on the left or not"

  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the slideover is closed."

  attr :close_button_position, :string,
    values: ["left", "right"],
    default: "right",
    doc: "The position of the close button."

  slot :additional_header_content,
    doc: "additional content to render in the header of the slideover"

  slot :inner_block, required: true, doc: "the inner block of the slideover"

  slot :footer, doc: "the footer of the slideover" do
    attr :class, :string, doc: "Additional CSS classes to add to the footer slot."
  end

  def slideover(assigns) do
    ~H"""
    <div class={[
      "bg-base-100 border-black-white/10 max-h-dvh flex",
      if(@compact, do: "min-h-64", else: "min-h-dvh h-full"),
      slideover_position_class(@left),
      slideover_size_class(@size)
    ]}>
      <div class="contents">
        <div
          :if={@open}
          class={["relative flex max-h-full flex-col overflow-clip", slideover_size_class(@size)]}
        >
          <.modal_header
            id={@id}
            gradient={@gradient}
            close_button
            close_button_position={@close_button_position}
            on_cancel={@on_cancel}
            title_wrapper_class="lg:pl-8 !py-6"
          >
            <.section_heading>
              {@title}
              <:subtitle :if={@subtitle}>{@subtitle}</:subtitle>
            </.section_heading>
            {render_slot(@additional_header_content)}
          </.modal_header>

          <div
            class={["h-full overflow-y-auto", @class]}
            phx-window-keydown={@on_cancel}
            phx-key="Escape"
          >
            {render_slot(@inner_block)}
          </div>

          <.modal_footer
            :for={footer <- @footer}
            id={@id}
            footer_class={class_names([footer[:class], "lg:px-8"])}
            gradient={@gradient}
          >
            {render_slot(@footer)}
          </.modal_footer>
        </div>
      </div>
    </div>
    """
  end

  defp slideover_position_class(left) do
    if left, do: "border-r", else: "border-l"
  end

  defp slideover_size_class(size) do
    case size do
      "sm" -> "w-full max-w-sm 3xl:w-[24rem]"
      "md" -> "w-full max-w-md 3xl:w-[28rem]"
      "lg" -> "w-full max-w-lg 3xl:w-[32rem]"
      "xl" -> "w-full max-w-xl 3xl:w-[36rem]"
    end
  end
end
