defmodule DataAggregatorWeb.LiveLogger do
  @moduledoc """
  LiveView hook to log events and params.
  """

  import Phoenix.LiveView, only: [attach_hook: 4]
  import Phoenix.Logger, only: [filter_values: 1]

  require Logger

  def on_mount(:default, params, session, socket) do
    socket
    |> log("MOUNT", %{"Params" => filter_values(params), "Session" => filter_values(session)})

    {:cont,
     socket
     |> attach_hook(:logger, :handle_params, &handle_params/3)
     |> attach_hook(:logger, :handle_event, &handle_event/3)}
  end

  defp log(socket, event, info) do
    info = info |> Enum.map_join("\n", fn {key, val} -> "  #{key}: #{inspect(val)}" end)
    Logger.info("[#{inspect(socket.view)}] #{event}\n#{info}")
  end

  defp handle_event(event, params, socket) do
    socket |> log("EVENT #{event}", %{"Params" => filter_values(params)})
    {:cont, socket}
  end

  defp handle_params(params, uri, socket) do
    socket |> log("PARAM #{uri}", %{"Params" => filter_values(params)})
    {:cont, socket}
  end
end
