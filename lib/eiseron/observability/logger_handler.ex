defmodule Eiseron.Observability.LoggerHandler do
  alias Eiseron.Observability.{Error, Log, LogBuffer}

  @internal_meta ~w(gl pid time mfa file line domain report_cb error_logger logger_formatter ansi_color crash_reason)a

  def log(event, %{config: config}) do
    dispatch(config, build_record(event))
    :ok
  end

  defp build_record(%{meta: %{crash_reason: {reason, stacktrace}} = meta})
       when is_list(stacktrace) do
    Error.build_record(crash_kind(reason), reason, stacktrace, error_meta(meta))
  end

  defp build_record(event), do: Log.build_record(event)

  defp crash_kind(reason) when is_exception(reason), do: :error
  defp crash_kind(_reason), do: :exit

  defp error_meta(meta), do: Map.drop(meta, @internal_meta)

  defp dispatch(%{sink: sink}, record) when is_function(sink, 1), do: sink.(record)
  defp dispatch(%{buffer: buffer}, record), do: LogBuffer.record(buffer, record)
  defp dispatch(_config, record), do: LogBuffer.record(record)
end
