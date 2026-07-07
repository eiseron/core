defmodule Eiseron.Observability.ErrorTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.Error

  @stack [
    {MyApp.Worker, :run, 2, [file: ~c"lib/my_app/worker.ex", line: 42]},
    {MyApp.Other, :call, 1, [file: ~c"lib/my_app/other.ex", line: 7]}
  ]

  defp record(meta \\ %{}),
    do: Error.build_record(:error, %RuntimeError{message: "boom"}, @stack, meta)

  test "an error is an OTLP log record at ERROR severity" do
    assert record().severity_number == 17
  end

  test "the body carries the exception message" do
    assert record().body == "boom"
  end

  test "records the OTel exception.type semantic attribute" do
    assert record().attributes["exception.type"] == "RuntimeError"
  end

  test "attaches the client-owned fingerprint" do
    assert record().attributes["fingerprint"] =~ ~r/\A[0-9a-f]{16}\z/
  end

  test "the stacktrace attribute keeps arity only, never argument values" do
    trace = record().attributes["exception.stacktrace"]
    assert trace =~ "MyApp.Worker.run/2 (lib/my_app/worker.ex:42)"
  end

  test "scrubs sensitive request metadata before it becomes an attribute" do
    assert record(%{user_id: 9, password: "hunter2"}).attributes[:password] == "[Filtered]"
  end

  test "keeps benign metadata alongside the exception attributes" do
    assert record(%{request_id: "abc"}).attributes[:request_id] == "abc"
  end
end
