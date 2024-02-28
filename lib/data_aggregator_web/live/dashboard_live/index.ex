defmodule DataAggregatorWeb.DashboardLive.Index do
  @moduledoc false
  use DataAggregatorWeb, :live_view

  import DataAggregatorWeb.Layouts.Primary, only: [page: 1]

  @options [
    %{value: "ft", label: "Fredrik Teschke"},
    %{value: "jd", label: "John Doe"},
    %{value: "ck1", label: "Clark Kent"},
    %{value: "ck2", label: "Clark Kent 2"},
    %{value: "ck3", label: "Clark Kent 3"},
    %{value: "ck4", label: "Clark Kent 4"},
    %{value: "ck5", label: "Clark Kent 5"},
    %{value: "ck6", label: "Clark Kent 6"},
    %{value: "ck7", label: "Clark Kent 7"},
    %{value: "ck8", label: "Clark Kent 8"},
    %{value: "ck9", label: "Clark Kent 9"},
    %{value: "ck10", label: "Clark Kent 10"},
    %{value: "ck11", label: "Clark Kent 11"},
    %{value: "ck12", label: "Clark Kent 12"},
    %{value: "ck13", label: "Clark Kent 13"},
    %{value: "ck14", label: "Clark Kent 14"},
    %{value: "ck15", label: "Clark Kent 15"},
    %{value: "ck16", label: "Clark Kent 16"},
    %{value: "ck17", label: "Clark Kent 17"},
    %{value: "ck18", label: "Clark Kent 18"},
    %{value: "ck19", label: "Clark Kent 19"}
  ]

  @options_with_groups %{
    "Group 1" => [
      %{value: "ft", label: "Fredrik Teschke"},
      %{value: "jd", label: "John Doe"}
    ],
    "Group 2" => [
      %{value: "ck1", label: "Clark Kent"},
      %{value: "ck2", label: "Clark Kent 2"},
      %{value: "ck3", label: "Clark Kent 3"},
      %{value: "ck4", label: "Clark Kent 4"},
      %{value: "ck5", label: "Clark Kent 5"},
      %{value: "ck6", label: "Clark Kent 6"},
      %{value: "ck7", label: "Clark Kent 7"},
      %{value: "ck8", label: "Clark Kent 8"},
      %{value: "ck9", label: "Clark Kent 9"},
      %{value: "ck10", label: "Clark Kent 10"},
      %{value: "ck11", label: "Clark Kent 11"},
      %{value: "ck12", label: "Clark Kent 12"},
      %{value: "ck13", label: "Clark Kent 13"},
      %{value: "ck14", label: "Clark Kent 14"},
      %{value: "ck15", label: "Clark Kent 15"},
      %{value: "ck16", label: "Clark Kent 16"},
      %{value: "ck17", label: "Clark Kent 17"},
      %{value: "ck18", label: "Clark Kent 18"},
      %{value: "ck19", label: "Clark Kent 19"}
    ]
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:options, @options)
     |> assign(:options_with_groups, @options_with_groups)
     |> assign(:selected, "jd")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_action(socket, socket.assigns.live_action, params)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page current="home">
      <.page_header class="px-6 pb-4 pt-1 lg:px-8 md:py-6"><%= ~t"Dashboard"m %></.page_header>

      <div class="max-w-sm space-y-8 px-6 lg:px-8">
        <div>
          <.section_heading text="Combobox simple" size="md" class="mb-2" />
          <x-combobox
            phx-hook="EventBridgeHook"
            phx-update="ignore"
            id="react-combobox"
            data-placeholder="Select a name"
            data-options={Jason.encode!(@options)}
            data-value={@selected}
          />
        </div>
        <div>
          <.section_heading text="Combobox with groups" size="md" class="mb-2" />
          <x-combobox
            phx-hook="EventBridgeHook"
            phx-update="ignore"
            id="react-combobox-with-groups"
            data-placeholder="Select a name"
            data-options={Jason.encode!(@options_with_groups)}
            data-value={@selected}
          />
        </div>
      </div>
    </.page>
    """
  end

  @impl true
  def handle_event("select", %{"value" => value}, socket) do
    {:noreply, assign(socket, :selected, value)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, ~t"Dashboard"m)
  end
end
