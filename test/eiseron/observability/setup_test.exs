defmodule Eiseron.Observability.SetupTest do
  use ExUnit.Case, async: false

  require Logger

  alias Eiseron.Observability
  alias Eiseron.Observability.LogBuffer

  @endpoint "http://collector:4318"

  defp handler_installed? do
    match?({:ok, _}, :logger.get_handler_config(:eiseron_observability))
  end

  defp shipped_records(timeout) do
    receive do
      {:posted, _endpoint, payload} ->
        payload
        |> get_in(["resourceLogs", Access.at(0), "scopeLogs", Access.at(0), "logRecords"])
        |> Kernel.++(shipped_records(timeout))
    after
      timeout -> []
    end
  end

  defp attribute(record, key) do
    Enum.find_value(record["attributes"], fn attr ->
      attr["key"] == key && attr["value"]["stringValue"]
    end)
  end

  test "setup is a no-op without an endpoint so dev and test stay quiet" do
    assert Observability.setup(service: :afinados) == :ok
    refute handler_installed?()
  end

  test "setup installs the handler and emitted logs reach the collector, scrubbed" do
    parent = self()

    start_supervised!(
      {LogBuffer,
       endpoint: @endpoint,
       resource: Observability.resource(service: :afinados),
       max_batch: 1,
       poster: fn endpoint, payload -> send(parent, {:posted, endpoint, payload}) end}
    )

    assert Observability.setup(service: :afinados, otlp_endpoint: @endpoint) == :ok
    on_exit(&Observability.detach/0)
    assert handler_installed?()

    Logger.error("marker_ship_probe", password: "hunter2")

    probe =
      Enum.find(shipped_records(300), &(&1["body"]["stringValue"] == "marker_ship_probe"))

    assert probe, "expected the emitted log to be shipped to the collector"
    assert attribute(probe, "password") == "[Filtered]"
  end

  test "detach removes the handler" do
    Observability.setup(service: :afinados, otlp_endpoint: @endpoint)
    assert handler_installed?()

    assert Observability.detach() == :ok
    refute handler_installed?()
  end
end
