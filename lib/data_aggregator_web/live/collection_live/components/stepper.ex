defmodule DataAggregatorWeb.CollectionLive.Collection.Components.Stepper do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :html

  @doc """
  Renders a stepper component.

  ## Examples

  ```heex
  <.stepper
    steps={3}
    current={2}
    links={[
      ~p"/step1",
      ~p"/step2",
      ~p"/step3"
    ]}
  />
  ```
  """
  attr :class, :string, default: nil
  attr :steps, :integer, default: 0, doc: "The total number of steps in the stepper."
  attr :links, :list, default: nil, doc: "The links for each step in the stepper."
  attr :current, :integer, required: true, doc: "The current step in the stepper."

  def stepper(assigns) do
    ~H"""
    <nav class={["flex items-center justify-start", @class]} aria-label="Progress">
      <p class="text-sm font-medium">
        {mgettext("Step %{current} of %{steps}",
          current: @current,
          steps: steps_count(@steps, @links)
        )}
      </p>
      <ol role="list" class="ml-8 flex items-center space-x-5">
        <%= if @links do %>
          <%= for {link, index} <- Enum.with_index(@links) do %>
            {render_step(index + 1, @current, link)}
          <% end %>
        <% else %>
          <%= for step  <- 1..@steps do %>
            {render_step(step, @current)}
          <% end %>
        <% end %>
      </ol>
    </nav>
    """
  end

  defp steps_count(_steps, links) when is_list(links), do: length(links)
  defp steps_count(steps, _links) when is_number(steps), do: steps
  defp steps_count(_steps, _links), do: 0

  defp render_step(step, current, link \\ nil) do
    cond do
      step < current ->
        completed_step(%{step: step, link: link})

      step == current ->
        current_step(%{step: step, link: link})

      true ->
        upcoming_step(%{step: step, link: link})
    end
  end

  defp completed_step(%{link: link} = assigns) when is_nil(link) == false do
    ~H"""
    <li>
      <.link
        patch={@link}
        class="size-2.5 bg-primary block rounded-full [@supports(color:color-mix(in_oklab,black,black))]:[@media(hover:hover)]:hover:bg-[color-mix(in_oklab,theme(colors.primary)_80%,black)]"
      >
        <span class="sr-only">{"Step #{@step}"}</span>
      </.link>
    </li>
    """
  end

  defp completed_step(assigns) do
    ~H"""
    <li>
      <div class="size-2.5 bg-primary block rounded-full">
        <span class="sr-only">{"Step #{@step}"}</span>
      </div>
    </li>
    """
  end

  defp current_step(%{link: link} = assigns) when is_nil(link) == false do
    ~H"""
    <li>
      <.link patch={@link} class="relative flex items-center justify-center" aria-current="step">
        <span class="size-5 absolute flex p-px" aria-hidden="true">
          <span class="bg-primary/20 h-full w-full rounded-full"></span>
        </span>
        <span class="size-2.5 bg-primary relative block rounded-full" aria-hidden="true"></span>
        <span class="sr-only">{"Step #{@step}"}</span>
      </.link>
    </li>
    """
  end

  defp current_step(assigns) do
    ~H"""
    <li>
      <div class="relative flex items-center justify-center" aria-current="step">
        <span class="size-5 absolute flex p-px" aria-hidden="true">
          <span class="bg-primary/20 h-full w-full rounded-full"></span>
        </span>
        <span class="size-2.5 bg-primary relative block rounded-full" aria-hidden="true"></span>
        <span class="sr-only">{"Step #{@step}"}</span>
      </div>
    </li>
    """
  end

  defp upcoming_step(%{link: link} = assigns) when is_nil(link) == false do
    ~H"""
    <li>
      <.link
        patch={@link}
        class="size-2.5 bg-neutral-content hover:bg-base-content/50 block rounded-full"
      >
        <span class="sr-only">{"Step #{@step}"}</span>
      </.link>
    </li>
    """
  end

  defp upcoming_step(assigns) do
    ~H"""
    <li>
      <div class="size-2.5 bg-neutral-content block rounded-full">
        <span class="sr-only">{"Step #{@step}"}</span>
      </div>
    </li>
    """
  end
end
