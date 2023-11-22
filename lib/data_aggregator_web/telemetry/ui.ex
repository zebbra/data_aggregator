defmodule DataAggregatorWeb.Telemetry.UI do
  @moduledoc false

  import TelemetryUI.Metrics

  def child_spec(_arg) do
    config()
    |> TelemetryUI.child_spec()
  end

  defp config do
    [
      metrics: metrics(),
      backend: backend()
    ]
  end

  defp metrics do
    [
      {"Phoenix", blah_metrics()},
      {"Ash", ash_metrics(), ui_options: [metrics_class: "grid-cols-8 gap-4"]}
    ]
  end

  defp blah_metrics do
    [
      last_value("my_app.users.total_count",
        description: "Number of users",
        ui_options: [unit: " users"]
      ),
      counter("phoenix.router_dispatch.stop.duration",
        description: "Number of requests",
        unit: {:native, :millisecond},
        ui_options: [unit: " requests"]
      ),
      value_over_time("vm.memory.total", unit: {:byte, :megabyte}),
      distribution("phoenix.router_dispatch.stop.duration",
        description: "Requests duration",
        unit: {:native, :millisecond},
        reporter_options: [buckets: [0, 100, 500, 2000]]
      )
    ] ++ ash_metrics()
  end

  defp ash_metrics do
    ash_action_tag_values = fn metadata ->
      %{action: action, resource_short_name: resource} = metadata
      %{resource_action: "#{action} #{resource}"}
    end

    actions = [:create, :update, :destroy]
    apis = [:records]

    metrics =
      for api <- apis, action <- actions do
        [
          counter("ash.#{api}.#{action}.stop.duration",
            description: "Number of calls",
            unit: {:native, :millisecond},
            ui_options: [class: "col-span-3", unit: " requests"]
          ),
          count_over_time("ash.#{api}.#{action}.stop.duration",
            description: "Number of requests over time",
            unit: {:native, :millisecond},
            ui_options: [class: "col-span-5", unit: " requests"]
          ),
          average("ash.#{api}.#{action}.stop.duration",
            description: "Requests duration",
            unit: {:native, :millisecond},
            ui_options: [class: "col-span-3", unit: " ms"]
          ),
          average_over_time("ash.#{api}.#{action}.stop.duration",
            description: "Requests duration over time",
            unit: {:native, :millisecond},
            ui_options: [class: "col-span-5", unit: " ms"]
          ),
          count_over_time("ash.#{api}.#{action}.stop.duration",
            description: "HTTP requests count per route",
            tags: [:resource_action],
            tag_values: ash_action_tag_values,
            unit: {:native, :millisecond},
            ui_options: [unit: " requests"],
            reporter_options: [class: "col-span-4"]
          ),
          counter("ash.#{api}.#{action}.stop.duration",
            description: "Count HTTP requests by route",
            tags: [:resource_action],
            tag_values: ash_action_tag_values,
            unit: {:native, :millisecond},
            ui_options: [unit: " requests"],
            reporter_options: [class: "col-span-4"]
          ),
          average_over_time("ash.#{api}.#{action}.stop.duration",
            description: "HTTP requests duration per route",
            tags: [:resource_action],
            tag_values: ash_action_tag_values,
            unit: {:native, :millisecond},
            reporter_options: [class: "col-span-4"]
          )
        ]
      end

    metrics |> List.flatten()
  end

  defp backend do
    %TelemetryUI.Backend.EctoPostgres{
      repo: DataAggregator.Repo,
      pruner_threshold: [months: -1],
      pruner_interval_ms: 84_000,
      max_buffer_size: 10_000,
      flush_interval_ms: 10_000
    }
  end
end
