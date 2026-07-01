defmodule Eiseron.ErrorMonitoring do
  @moduledoc """
  Shared error-monitoring wiring (Sentry / GlitchTip) for Eiseron products.

  Each app, on boot, calls `attach/0`, points Sentry's `:client` at
  `Eiseron.ErrorMonitoring.FinchClient`, and wires `body_scrubber/1` into
  `Sentry.PlugContext`. The DSN, environment and release stay per-app.
  """

  alias Eiseron.ErrorMonitoring.Scrubber

  def attach do
    :logger.add_handler(:eiseron_error_monitoring, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line], capture_log_messages: false}
    })
  end

  def body_scrubber(%Plug.Conn{} = conn) do
    conn
    |> Sentry.PlugContext.default_body_scrubber()
    |> Scrubber.scrub_params()
  end

  def before_send(%{request: %{query_string: query} = request} = event)
      when is_binary(query) and query != "" do
    scrubbed = query |> URI.decode_query() |> Scrubber.scrub_params() |> URI.encode_query()
    %{event | request: %{request | query_string: scrubbed}}
  end

  def before_send(event), do: event
end
