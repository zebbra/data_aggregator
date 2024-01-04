defmodule DataAggregatorWeb.CollectionLive.Components do
  use DataAggregatorWeb, :html

  attr :state, :atom, default: :not_encoded
  attr :small, :boolean, default: false

  def encoding_state(assigns) do
    cond do
      assigns.state in [:encoded] ->
        ~H"""
        <div
          :if={!assigns.small}
          class="badge badge-lg alert alert-success bg-success/10 text-success gap-2"
        >
          <div class="hero-check-circle-solid"></div>
          <div>Successful</div>
        </div>

        <div :if={assigns.small} class="tooltip tooltip-success" data-tip="Successful">
          <div class="badge badge-sm alert alert-success bg-success/10 text-success gap-2">
            <div class="hero-check-circle-solid"></div>
          </div>
        </div>
        """

      assigns.state in [:failed] ->
        ~H"""
        <div :if={!assigns.small} class="badge badge-lg alert alert-error bg-error/10 text-error gap-2">
          <div class="hero-x-circle-solid"></div>
          <div>Failed</div>
        </div>

        <div :if={assigns.small} class="tooltip tooltip-error" data-tip="Failed">
          <div class="badge badge-sm alert alert-error bg-error/10 text-error gap-2">
            <div class="hero-x-circle-solid"></div>
          </div>
        </div>
        """

      assigns.state in [:encoding, :queued] ->
        ~H"""
        <div :if={!assigns.small} class="badge badge-lg alert alert-info gap-2 text-slate-500">
          <div class="hero-cog-6-tooth-solid animate-spin"></div>
          <div>Processing</div>
        </div>

        <div :if={assigns.small} class="tooltip tooltip-info" data-tip="Processing">
          <div class="badge badge-sm alert alert-info gap-2 text-slate-500">
            <div class="hero-cog-6-tooth-solid animate-spin"></div>
          </div>
        </div>
        """

      assigns.state in [:incomplete, :imported] ->
        ~H"""
        <div :if={!assigns.small} class="badge badge-lg alert alert-warning text-warning gap-2">
          <div class="hero-exclamation-triangle"></div>
          <div>Not encoded</div>
        </div>

        <div :if={assigns.small} class="tooltip tooltip-warning" data-tip="not encoded">
          <div class="badge badge-sm alert alert-warning text-warning gap-2">
            <div class="hero-exclamation-triangle"></div>
          </div>
        </div>
        """

      true ->
        ~H"""
        <div :if={!assigns.small} class="badge badge-lg alert alert-ghost gap-2 text-slate-500">
          <div class="hero-question-mark-circle-solid"></div>
          <div>Unknown (<%= assigns.state %>)</div>
        </div>

        <div :if={assigns.small} class="tooltip" data-tip={"Unknown (#{assigns.state})"}>
          <div class="badge badge-sm alert gap-2 text-slate-500">
            <div class="hero-question-mark-circle-solid"></div>
          </div>
        </div>
        """
    end
  end

  defmacro __using__(_opts) do
    quote do
      import DataAggregatorWeb.CollectionLive.Components
    end
  end
end
