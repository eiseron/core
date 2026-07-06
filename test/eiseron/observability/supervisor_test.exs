defmodule Eiseron.Observability.SupervisorTest do
  use ExUnit.Case, async: false

  alias Eiseron.Observability.{LogBuffer, Supervisor}

  test "supervises the buffer and its finch pool when export is enabled" do
    start_supervised!({Supervisor, service: :afinados, otlp_endpoint: "http://collector:4318"})

    assert Process.alive?(Process.whereis(LogBuffer))
    assert Process.alive?(Process.whereis(LogBuffer.Finch))
  end

  test "starts no children when export is disabled" do
    pid = start_supervised!({Supervisor, service: :afinados})

    assert Elixir.Supervisor.which_children(pid) == []
  end
end
