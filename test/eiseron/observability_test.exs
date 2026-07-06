defmodule Eiseron.ObservabilityTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability

  @opts [
    service: :afinados,
    env: :prod,
    version: "1.2.3",
    otlp_endpoint: "http://observability-collector:4318"
  ]

  test "resource carries the service identity as OTel semantic attributes" do
    assert Observability.resource(@opts) == %{
             "service.name" => "afinados",
             "deployment.environment" => "prod",
             "service.version" => "1.2.3"
           }
  end

  test "resource falls back to safe defaults when env and version are absent" do
    resource = Observability.resource(service: :afinados)
    assert resource["deployment.environment"] == "dev"
    assert resource["service.version"] == "0.0.0"
  end

  test "config points the exporter at the given collector over http" do
    exporter = Observability.config(@opts)[:opentelemetry_exporter]
    assert exporter[:otlp_endpoint] == "http://observability-collector:4318"
    assert exporter[:otlp_protocol] == :http_protobuf
  end

  test "config batches spans and exports via otlp when an endpoint is set" do
    otel = Observability.config(@opts)[:opentelemetry]
    assert otel[:span_processor] == :batch
    assert otel[:traces_exporter] == :otlp
    assert otel[:resource]["service.name"] == "afinados"
  end

  test "export is disabled when no endpoint is configured (dev/test)" do
    opts = Keyword.put(@opts, :otlp_endpoint, nil)
    assert Observability.export?(opts) == false
    assert Observability.config(opts)[:opentelemetry][:traces_exporter] == :none
  end

  test "a blank endpoint is treated as no endpoint" do
    refute Observability.export?(Keyword.put(@opts, :otlp_endpoint, ""))
  end

  test "export is enabled when an endpoint is present" do
    assert Observability.export?(@opts)
  end
end
