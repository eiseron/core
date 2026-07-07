defmodule Eiseron.Observability.Error do
  alias Eiseron.ErrorMonitoring.Scrubber
  alias Eiseron.Observability.Fingerprint

  def build_record(kind, reason, stacktrace, meta \\ %{}) do
    %{
      severity_number: 17,
      severity_text: "ERROR",
      time_unix_nano: nil,
      body: message(kind, reason, stacktrace),
      attributes: build_attributes(kind, reason, stacktrace, meta)
    }
  end

  defp build_attributes(kind, reason, stacktrace, meta) do
    meta
    |> Scrubber.scrub_params()
    |> Map.merge(%{
      "exception.type" => Fingerprint.exception_type(kind, reason),
      "exception.message" => message(kind, reason, stacktrace),
      "exception.stacktrace" => format_stacktrace(stacktrace),
      "fingerprint" => Fingerprint.build(kind, reason, stacktrace)
    })
  end

  defp message(:error, reason, stacktrace) do
    :error |> Exception.normalize(reason, stacktrace) |> Exception.message()
  end

  defp message(kind, reason, _stacktrace), do: Exception.format_banner(kind, reason)

  defp format_stacktrace(stacktrace) do
    stacktrace |> Enum.map(&format_frame/1) |> Enum.join("\n")
  end

  defp format_frame({module, function, arity, location}) do
    "#{inspect(module)}.#{function}/#{frame_arity(arity)} (#{frame_location(location)})"
  end

  defp format_frame(other), do: inspect(other)

  defp frame_arity(arity) when is_integer(arity), do: arity
  defp frame_arity(args) when is_list(args), do: length(args)

  defp frame_location(location) do
    file = location |> Keyword.get(:file, ~c"") |> to_string()
    "#{file}:#{Keyword.get(location, :line, 0)}"
  end
end
