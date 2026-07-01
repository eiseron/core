defmodule Eiseron.ErrorMonitoring do
  @moduledoc """
  Single facade for error monitoring across Eiseron products.

  Everything goes through this module — Sentry is an implementation detail:

      # config/config.exs
      config :sentry, Eiseron.ErrorMonitoring.config()

      # config/runtime.exs (prod/preview)
      config :sentry,
        Eiseron.ErrorMonitoring.runtime_config(
          dsn: System.get_env("ERROR_MONITORING_DSN"),
          environment: config_env(),
          release: to_string(Application.spec(:my_app, :vsn))
        )

      # application.ex — on boot
      Eiseron.ErrorMonitoring.attach()

      # endpoint.ex
      use Eiseron.ErrorMonitoring.PlugCapture
      plug Eiseron.ErrorMonitoring.PlugContext
  """

  alias Eiseron.ErrorMonitoring.{FinchClient, Scrubber}

  def config do
    [
      client: FinchClient,
      before_send: {__MODULE__, :before_send},
      send_default_pii: false
    ]
  end

  def runtime_config(opts) do
    [
      dsn: Keyword.get(opts, :dsn),
      environment_name: to_string(Keyword.get(opts, :environment)),
      release: Keyword.get(opts, :release)
    ]
  end

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
