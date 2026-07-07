defmodule Eiseron.Observability.ReportTest do
  use ExUnit.Case, async: false

  alias Eiseron.Observability
  alias Eiseron.Observability.LogBuffer

  @stack [{MyApp.Worker, :run, 2, [file: ~c"lib/my_app/worker.ex", line: 42]}]

  setup do
    parent = self()

    start_supervised!(
      {LogBuffer,
       endpoint: "http://collector:4318",
       resource: %{"service.name" => "afinados"},
       max_batch: 1,
       poster: fn _endpoint, payload -> send(parent, {:posted, payload}) end}
    )

    :ok
  end

  defp reported_record do
    Observability.report(:error, %RuntimeError{message: "boom"}, @stack, %{user_id: 7})
    assert_receive {:posted, payload}

    [record] =
      get_in(payload, ["resourceLogs", Access.at(0), "scopeLogs", Access.at(0), "logRecords"])

    record
  end

  defp attribute(record, key) do
    Enum.find_value(record["attributes"], fn a -> a["key"] == key && a["value"]["stringValue"] end)
  end

  test "report/4 ships the error at ERROR severity" do
    assert reported_record()["severityText"] == "ERROR"
  end

  test "report/4 carries the OTel exception type" do
    assert attribute(reported_record(), "exception.type") == "RuntimeError"
  end

  test "report/4 attaches the client-owned fingerprint" do
    assert attribute(reported_record(), "fingerprint") =~ ~r/\A[0-9a-f]{16}\z/
  end
end
