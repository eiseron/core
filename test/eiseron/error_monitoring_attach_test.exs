defmodule Eiseron.ErrorMonitoringAttachTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Eiseron.ErrorMonitoring

  @handler_id :eiseron_error_monitoring

  defp installed?, do: match?({:ok, _}, :logger.get_handler_config(@handler_id))

  setup do
    on_exit(fn ->
      :logger.remove_handler(@handler_id)
      Application.delete_env(:eiseron_core, :error_backend)
    end)
  end

  test "attach installs the GlitchTip logger handler by default" do
    ErrorMonitoring.attach()
    assert installed?()
  end

  test "attach with backend: :otel skips the Sentry handler" do
    ErrorMonitoring.attach(backend: :otel)
    refute installed?()
  end

  test "the error_backend app config selects the otel backend" do
    Application.put_env(:eiseron_core, :error_backend, :otel)
    ErrorMonitoring.attach()
    refute installed?()
  end

  test "an unknown backend falls back to installing GlitchTip" do
    ErrorMonitoring.attach(backend: :typo)
    assert installed?()
  end

  test "an unknown backend warns about the fallback" do
    log = capture_log(fn -> ErrorMonitoring.attach(backend: :typo) end)
    assert log =~ "unknown error_backend :typo"
  end
end
