defmodule Eiseron.Observability.OTLP do
  alias Eiseron.ErrorMonitoring.Scrubber

  @scope "eiseron_core"

  def build_logs_payload(records, resource) when is_list(records) do
    %{
      "resourceLogs" => [
        %{
          "resource" => %{"attributes" => build_attributes(resource)},
          "scopeLogs" => [
            %{
              "scope" => %{"name" => @scope},
              "logRecords" => Enum.map(records, &build_log_record/1)
            }
          ]
        }
      ]
    }
  end

  defp build_log_record(record) do
    scrubbed = Scrubber.scrub_record(record)

    %{
      "severityNumber" => scrubbed.severity_number,
      "severityText" => scrubbed.severity_text,
      "body" => build_any_value(scrubbed.body),
      "attributes" => build_attributes(scrubbed.attributes)
    }
    |> put_present("timeUnixNano", format_nano(scrubbed[:time_unix_nano]))
  end

  defp build_attributes(map) when is_map(map) do
    Enum.map(map, fn {key, value} ->
      %{"key" => to_string(key), "value" => build_any_value(value)}
    end)
  end

  def build_any_value(value) when is_binary(value), do: %{"stringValue" => value}
  def build_any_value(value) when is_boolean(value), do: %{"boolValue" => value}
  def build_any_value(value) when is_integer(value), do: %{"intValue" => to_string(value)}
  def build_any_value(value) when is_float(value), do: %{"doubleValue" => value}
  def build_any_value(value) when is_atom(value), do: %{"stringValue" => to_string(value)}

  def build_any_value(value) when is_list(value) do
    %{"arrayValue" => %{"values" => Enum.map(value, &build_any_value/1)}}
  end

  def build_any_value(value), do: %{"stringValue" => inspect(value)}

  defp format_nano(nil), do: nil
  defp format_nano(nano) when is_integer(nano), do: to_string(nano)

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)
end
