defmodule Eiseron.Observability.LoggerHandler do

  alias Eiseron.Observability.{Log, LogBuffer}

  def log(event, %{config: config}) do
    dispatch(config, Log.build_record(event))
    :ok
  end

  defp dispatch(%{sink: sink}, record) when is_function(sink, 1), do: sink.(record)
  defp dispatch(%{buffer: buffer}, record), do: LogBuffer.record(buffer, record)
  defp dispatch(_config, record), do: LogBuffer.record(record)
end
