defmodule Eiseron.Observability.LogBufferTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.LogBuffer

  @resource %{"service.name" => "afinados"}

  defp record(body) do
    %{severity_number: 9, severity_text: "INFO", body: body, attributes: %{}, time_unix_nano: nil}
  end

  defp start_buffer(overrides) do
    parent = self()

    opts =
      Keyword.merge(
        [
          endpoint: "http://collector:4318",
          resource: @resource,
          flush_interval: 10_000,
          max_batch: 100,
          poster: fn endpoint, payload -> send(parent, {:posted, endpoint, payload}) end
        ],
        overrides
      )

    start_supervised!({LogBuffer, opts})
  end

  defp bodies(payload) do
    payload
    |> get_in(["resourceLogs", Access.at(0), "scopeLogs", Access.at(0), "logRecords"])
    |> Enum.map(& &1["body"]["stringValue"])
  end

  test "posts a single OTLP payload once the batch size is reached" do
    buffer = start_buffer(max_batch: 2)

    LogBuffer.record(buffer, record("a"))
    refute_receive {:posted, _, _}, 50

    LogBuffer.record(buffer, record("b"))
    assert_receive {:posted, "http://collector:4318", payload}
    assert bodies(payload) == ["a", "b"]
  end

  test "preserves chronological order (oldest first) within a batch" do
    buffer = start_buffer(max_batch: 3)

    Enum.each(["first", "second", "third"], &LogBuffer.record(buffer, record(&1)))

    assert_receive {:posted, _, payload}
    assert bodies(payload) == ["first", "second", "third"]
  end

  test "flushes pending records when the interval elapses" do
    buffer = start_buffer(flush_interval: 30, max_batch: 100)

    LogBuffer.record(buffer, record("delayed"))

    assert_receive {:posted, _, payload}, 200
    assert bodies(payload) == ["delayed"]
  end

  test "does not post when there is nothing buffered on flush" do
    buffer = start_buffer(flush_interval: 20)
    send(buffer, :flush)

    refute_receive {:posted, _, _}, 60
  end
end
