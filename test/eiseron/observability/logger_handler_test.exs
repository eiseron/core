defmodule Eiseron.Observability.LoggerHandlerTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.LoggerHandler

  test "builds a record from the event and hands it to the configured sink" do
    parent = self()
    config = %{config: %{sink: fn record -> send(parent, {:record, record}) end}}

    event = %{level: :error, msg: {:string, "boom"}, meta: %{request_id: "abc"}}
    assert LoggerHandler.log(event, config) == :ok

    assert_receive {:record, record}
    assert record.severity_text == "ERROR"
    assert record.body == "boom"
    assert record.attributes[:request_id] == "abc"
  end
end
