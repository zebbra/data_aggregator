defmodule DataAggregatorWeb.CollectionLive.Import.Components.Summary do
  @moduledoc """
  This module contains components for the collection > import live view.
  """

  use DataAggregatorWeb, :html

  import DataAggregatorWeb.CollectionLive.Import.Components.Stepper, only: [stepper: 1]
  import DataAggregatorWeb.CollectionLive.Import.Helpers, only: [current_step: 1]

  def summary(assigns) do
    ~H"""
    <div>
      <.stepper
        current={current_step(@action)}
        links={[nil, ~p"/collections/#{@collection}/imports/#{@import}/edit", nil]}
      />
      <div class="space-y-8">
        <.heading
          title={~t"Summary"m}
          subtitle={~t"Please review the summary of your import."m}
          class="border-b border-black-white/10 py-4"
        />
      </div>
    </div>
    """
  end
end
