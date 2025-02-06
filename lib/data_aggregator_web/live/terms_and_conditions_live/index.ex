defmodule DataAggregatorWeb.TermsAndConditionsLive.Index do
  @moduledoc false

  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="terms" current_user={@current_user}>
      <:portal>
        <.modal
          id="terms_modal"
          show={true}
          size="2xl"
          responsive
          backdrop={false}
          overflow="manual"
          on_cancel={JS.navigate(~p"/terms")}
        >
          <div class="contents">
            <.modal_header id="terms_modal_header">
              <.section_heading text={~t"Terms and Conditions"m} class="mt-4" />
            </.modal_header>
            <div class="h-full space-y-12 overflow-y-auto px-6 py-8">
              <p class="text-sm">
                {~t"By accessing the Data Aggregator, you agree to comply with the conditions laid down on our policy. These terms govern the use of our services and content. We encourage you to read them carefully. If you do not agree to these terms, please do not use our platform."m}
              </p>
              <p class="text-sm">
                {~t"I have read and agree with the"m}
                <.link
                  class="link link-primary link-hover"
                  target="_blank"
                  href={Application.get_env(:data_aggregator, :terms_url)}
                >
                  {~t"terms of use"}
                  <.icon name="hero-arrow-top-right-on-square" class="size-4" />
                </.link>
                {~t"of the DAGI and accept full responsibility for the data I upload and publish."m}
              </p>
              <p class="text-sm">
                {~t"The terms of use are currently under revision and may change in the coming weeks to better meet legal and regulatory requirements. In the time being, the publication of the data will be done on the GBIF test environment. The publication of the data to GBIF will become effective on the 27th of January, date on which you will be asked to revise and re-publish your dataset, by accepting the final terms of use of the DAGI."m}
              </p>
              <p class="text-sm">
                {~t"Thank you for your understanding and welcome!"m}
              </p>
            </div>
          </div>
          <.modal_footer id="terms_modal_footer">
            <button type="submit" class="btn btn-primary" phx-click="terms:accept">
              {~t"Accept"m}
            </button>
            <button type="button" class="btn btn-error" phx-click="terms:decline">
              {~t"Decline"m}
            </button>
          </.modal_footer>
        </.modal>
      </:portal>
    </.page>
    """
  end

  @impl true
  def handle_event("terms:decline", _params, socket) do
    {:noreply, redirect(socket, to: "/sign-out")}
  end

  @impl true
  def handle_event("terms:accept", _params, socket) do
    Ash.update!(socket.assigns.current_user, action: :accept_terms)

    socket
    |> push_navigate(to: ~p"/")
    |> noreply()
  end
end
