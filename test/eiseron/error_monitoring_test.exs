defmodule Eiseron.ErrorMonitoringTest do
  use ExUnit.Case, async: true

  alias Eiseron.ErrorMonitoring

  test "body_scrubber redacts sensitive params from the conn" do
    conn = %Plug.Conn{params: %{"password" => "x", "clip" => "3"}, body_params: %{"password" => "x"}}

    assert ErrorMonitoring.body_scrubber(conn)["password"] == "[Filtered]"
  end

  test "body_scrubber keeps benign params from the conn" do
    conn = %Plug.Conn{params: %{"clip" => "3"}, body_params: %{"clip" => "3"}}

    assert ErrorMonitoring.body_scrubber(conn)["clip"] == "3"
  end

  test "before_send redacts a sensitive query param" do
    event = %{request: %{query_string: "email=a@b.com&x=1"}}
    scrubbed = ErrorMonitoring.before_send(event)

    assert URI.decode_query(scrubbed.request.query_string)["email"] == "[Filtered]"
  end

  test "before_send keeps a benign query param" do
    event = %{request: %{query_string: "x=1"}}
    scrubbed = ErrorMonitoring.before_send(event)

    assert URI.decode_query(scrubbed.request.query_string)["x"] == "1"
  end

  test "before_send passes an event without a query string through unchanged" do
    event = %{request: %{query_string: ""}}

    assert ErrorMonitoring.before_send(event) == event
  end
end
