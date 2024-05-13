defmodule DataAggregatorWeb.Components.Alert do
  @moduledoc """
  Alert components.
  """

  use Phoenix.Component

  import DataAggregatorWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
    Renders an alert.

    ## Examples

        <.alert>
          This is an alert.
        </.alert>
  """
  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :text, :string, default: nil
  attr :on_cancel, JS, default: %JS{}, doc: "JS commands to run when the modal is cancelled."
  attr :on_confirm, JS, default: %JS{}, doc: "JS commands to run when the modal is closed."
  attr :form, :boolean, default: false, doc: "Whether the alert provides a form."

  attr :size, :string,
    values: ["xs", "sm", "md", "lg", "xl", "2xl", "3xl", "4xl", "5xl"],
    default: "md"

  slot :inner_block, required: false

  def alert(assigns) do
    ~H"""
    <dialog
      id={@id}
      class="modal"
      phx-hook="DialogHook"
      data-cancel={@on_cancel}
      data-confirm={@on_confirm}
    >
      <div class={["modal-box max-h-[calc(100dvh-5em)]", size(@size)]}>
        <.focus_wrap id={"#{@id}_content"}>
          <h2 class="label-text text-base/6 font-semibold sm:text-sm/6">
            <%= @title || ~t"Are you sure?"m %>
          </h2>
          <p :if={@text} class="text-base/6 sm:text-sm/6"><%= @text %></p>
          <%= render_slot(@inner_block) %>
          <form :if={@form == false} method="dialog">
            <div class="modal-action">
              <button class="btn btn-ghost" value="cancel">
                <%= ~t"Cancel"m %>
              </button>
              <button type="submit" value="confirm" class="btn btn-primary">
                <%= ~t"OK"m %>
              </button>
            </div>
          </form>
        </.focus_wrap>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button><%= ~t"close"m %></button>
      </form>
    </dialog>
    """
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp size(size) do
    case String.to_atom(size) do
      :xs -> "sm:max-w-xs"
      :sm -> "sm:max-w-sm"
      :md -> "sm:max-w-md"
      :lg -> "sm:max-w-lg"
      :xl -> "sm:max-w-xl"
      :"2xl" -> "sm:max-w-2xl"
      :"3xl" -> "sm:max-w-3xl"
      :"4xl" -> "sm:max-w-4xl"
      :"5xl" -> "sm:max-w-5xl"
      _ -> "sm:max-w-5xl"
    end
  end
end
