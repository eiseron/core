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

  test "config points the client at the Finch-backed implementation" do
    assert ErrorMonitoring.config()[:client] == ErrorMonitoring.FinchClient
  end

  test "config keeps PII off by default" do
    assert ErrorMonitoring.config()[:send_default_pii] == false
  end

  test "runtime_config carries the given dsn" do
    assert ErrorMonitoring.runtime_config(dsn: "d")[:dsn] == "d"
  end

  test "runtime_config stringifies the environment" do
    assert ErrorMonitoring.runtime_config(environment: :prod)[:environment_name] == "prod"
  end

  test "config wires the query-scrubbing before_send" do
    assert ErrorMonitoring.config()[:before_send] == {ErrorMonitoring, :before_send}
  end

  test "body_scrubber preserves the SDK credit-card masking" do
    card = "4111111111111111"
    conn = %Plug.Conn{params: %{"note" => card}, body_params: %{"note" => card}}

    refute ErrorMonitoring.body_scrubber(conn)["note"] == card
  end
end
