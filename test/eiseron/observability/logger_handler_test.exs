defmodule Eiseron.Observability.LoggerHandlerTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.LoggerHandler

  @crash_stack [{MyApp.Worker, :run, 2, [file: ~c"lib/my_app/worker.ex", line: 42]}]
  @crash_event %{
    level: :error,
    msg: {:string, "Process crashed"},
    meta: %{crash_reason: {%RuntimeError{message: "boom"}, @crash_stack}, request_id: "abc"}
  }

  defp dispatched(event) do
    parent = self()
    LoggerHandler.log(event, %{config: %{sink: fn record -> send(parent, {:record, record}) end}})
    assert_receive {:record, record}
    record
  end

  test "a plain string log becomes a log record with its metadata" do
    record = dispatched(%{level: :info, msg: {:string, "hello"}, meta: %{request_id: "abc"}})
    assert record.attributes[:request_id] == "abc"
  end

  test "a plain log carries no exception attribute" do
    record = dispatched(%{level: :info, msg: {:string, "hello"}, meta: %{}})
    refute Map.has_key?(record.attributes, "exception.type")
  end

  test "a crash_reason event records the OTel exception type" do
    assert dispatched(@crash_event).attributes["exception.type"] == "RuntimeError"
  end

  test "a crash_reason event attaches a fingerprint" do
    assert dispatched(@crash_event).attributes["fingerprint"] =~ ~r/\A[0-9a-f]{16}\z/
  end

  test "a crash_reason event keeps the request metadata" do
    assert dispatched(@crash_event).attributes[:request_id] == "abc"
  end
end
