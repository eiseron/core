defmodule Eiseron.Observability.TracesTest do
  use ExUnit.Case, async: false

  alias Eiseron.Observability.Traces

  @endpoint "http://collector:4318"

  defp enabled(extra), do: [service: :afinados, otlp_endpoint: @endpoint] ++ extra

  test "is a no-op when export is disabled so dev and test attach nothing" do
    assert Traces.setup(service: :afinados, ecto: [[:idle_repo]]) == :ok
    assert :telemetry.list_handlers([:idle_repo, :query]) == []
  end

  test "attaches an ecto span handler for each configured repo prefix" do
    prefixes = [[:trace_test, :repo], [:trace_test, :replica]]

    on_exit(fn ->
      Enum.each(prefixes, &:telemetry.detach({OpentelemetryEcto, &1 ++ [:query]}))
    end)

    assert Traces.setup(enabled(ecto: prefixes)) == :ok

    assert :telemetry.list_handlers([:trace_test, :repo, :query]) != []
    assert :telemetry.list_handlers([:trace_test, :replica, :query]) != []
  end

  test "attaches phoenix endpoint handlers when phoenix instrumentation is requested" do
    on_exit(fn ->
      :telemetry.detach({OpentelemetryPhoenix, :endpoint_start})
      :telemetry.detach({OpentelemetryPhoenix, :router_dispatch_start})
    end)

    assert Traces.setup(enabled(phoenix: [adapter: :bandit])) == :ok

    assert :telemetry.list_handlers([:phoenix, :endpoint, :start]) != []
  end

  test "leaves phoenix untouched for a non-web service" do
    assert Traces.setup(enabled(ecto: [[:worker_repo]])) == :ok
    on_exit(fn -> :telemetry.detach({OpentelemetryEcto, [:worker_repo, :query]}) end)

    assert :telemetry.list_handlers([:phoenix, :endpoint, :start]) == []
  end
end
