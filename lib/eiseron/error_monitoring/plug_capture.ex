defmodule Eiseron.ErrorMonitoring.PlugCapture do
  @moduledoc "Endpoint helper: `use Eiseron.ErrorMonitoring.PlugCapture` to report Plug errors."

  defmacro __using__(_opts) do
    quote do
      use Sentry.PlugCapture
    end
  end
end
