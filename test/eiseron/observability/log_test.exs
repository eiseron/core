defmodule Eiseron.Observability.LogTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.Log

  defp event(overrides) do
    Map.merge(%{level: :info, msg: {:string, "hello"}, meta: %{}}, Map.new(overrides))
  end

  test "maps the log level to the OTel severity number and text" do
    record = Log.build_record(event(level: :error))
    assert record.severity_number == 17
    assert record.severity_text == "ERROR"
  end

  test "unknown levels fall back to info severity" do
    assert Log.severity_number(:something_else) == 9
  end

  test "renders a string message as the record body" do
    record = Log.build_record(event(msg: {:string, ["hel", "lo"]}))
    assert record.body == "hello"
  end

  test "renders a format-and-args message into the body" do
    record = Log.build_record(event(msg: {~c"user ~s logged in", ["ana"]}))
    assert record.body == "user ana logged in"
  end

  test "scrubs sensitive metadata before it becomes an attribute" do
    record = Log.build_record(event(meta: %{user_id: 7, password: "hunter2", email: "a@b.com"}))
    assert record.attributes[:user_id] == 7
    assert record.attributes[:password] == "[Filtered]"
    assert record.attributes[:email] == "[Filtered]"
  end

  test "promotes source location metadata to OTel code.* attributes" do
    meta = %{file: ~c"lib/foo.ex", line: 42, mfa: {Foo.Bar, :run, 2}}
    record = Log.build_record(event(meta: meta))
    assert record.attributes["code.filepath"] == "lib/foo.ex"
    assert record.attributes["code.lineno"] == 42
    assert record.attributes["code.function"] == "Foo.Bar.run/2"
  end

  test "drops internal logger bookkeeping keys from attributes" do
    meta = %{gl: :erlang.list_to_pid(~c"<0.1.0>"), domain: [:elixir], request_id: "abc"}
    record = Log.build_record(event(meta: meta))
    assert record.attributes == %{request_id: "abc"}
  end

  test "carries the event timestamp as unix nanoseconds" do
    record = Log.build_record(event(meta: %{time: 1_700_000_000_000_000}))
    assert record.time_unix_nano == 1_700_000_000_000_000_000
  end
end
