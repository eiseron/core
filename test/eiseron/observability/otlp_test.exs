defmodule Eiseron.Observability.OTLPTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.OTLP

  @resource %{"service.name" => "afinados", "deployment.environment" => "prod"}

  @record %{
    time_unix_nano: 1_700_000_000_000_000_000,
    severity_number: 17,
    severity_text: "ERROR",
    body: "boom",
    attributes: %{"code.lineno" => 42, retriable: false}
  }

  defp logs_payload, do: OTLP.build_logs_payload([@record], @resource)

  defp only_scope_logs do
    [resource_logs] = logs_payload()["resourceLogs"]
    [scope_logs] = resource_logs["scopeLogs"]
    scope_logs
  end

  test "nests the resource attributes under resourceLogs" do
    [resource_logs] = logs_payload()["resourceLogs"]
    attributes = resource_logs["resource"]["attributes"]

    assert %{"key" => "service.name", "value" => %{"stringValue" => "afinados"}} in attributes
  end

  test "tags the emitting scope as eiseron_core" do
    assert only_scope_logs()["scope"] == %{"name" => "eiseron_core"}
  end

  test "encodes the log record severity, body and timestamp" do
    [log_record] = only_scope_logs()["logRecords"]
    assert log_record["severityNumber"] == 17
    assert log_record["severityText"] == "ERROR"
    assert log_record["body"] == %{"stringValue" => "boom"}
    assert log_record["timeUnixNano"] == "1700000000000000000"
  end

  test "omits the timestamp when the event carried none" do
    [log_record] =
      OTLP.build_logs_payload([Map.put(@record, :time_unix_nano, nil)], @resource)
      |> get_in(["resourceLogs", Access.at(0), "scopeLogs", Access.at(0), "logRecords"])

    refute Map.has_key?(log_record, "timeUnixNano")
  end

  test "wraps integers as stringified intValue per the OTLP spec" do
    assert OTLP.build_any_value(42) == %{"intValue" => "42"}
  end

  test "wraps booleans as boolValue" do
    assert OTLP.build_any_value(false) == %{"boolValue" => false}
  end

  test "wraps a list as an OTLP arrayValue" do
    assert OTLP.build_any_value(["a", 1]) == %{
             "arrayValue" => %{"values" => [%{"stringValue" => "a"}, %{"intValue" => "1"}]}
           }
  end
end
