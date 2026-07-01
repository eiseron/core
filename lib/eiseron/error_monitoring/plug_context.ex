defmodule Eiseron.ErrorMonitoring.PlugContext do
  @moduledoc "Plug that attaches scrubbed request context to error events."

  @behaviour Plug

  @impl true
  def init(opts) do
    opts
    |> Keyword.put_new(:body_scrubber, &Eiseron.ErrorMonitoring.body_scrubber/1)
    |> Sentry.PlugContext.init()
  end

  @impl true
  def call(conn, opts), do: Sentry.PlugContext.call(conn, opts)
end
