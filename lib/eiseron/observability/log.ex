defmodule Eiseron.Observability.Log do

  alias Eiseron.ErrorMonitoring.Scrubber

  @severity_numbers %{
    debug: 5,
    info: 9,
    notice: 10,
    warning: 13,
    warn: 13,
    error: 17,
    critical: 19,
    alert: 21,
    emergency: 23
  }

  @internal_meta ~w(gl pid time mfa file line domain report_cb error_logger logger_formatter ansi_color)a

  def build_record(%{level: level, msg: msg, meta: meta}) do
    %{
      time_unix_nano: time_unix_nano(meta),
      severity_number: severity_number(level),
      severity_text: severity_text(level),
      body: format_body(msg),
      attributes: build_attributes(meta)
    }
  end

  def severity_number(level), do: Map.get(@severity_numbers, level, 9)

  def severity_text(level), do: level |> to_string() |> String.upcase()

  defp time_unix_nano(%{time: time}) when is_integer(time), do: time * 1_000
  defp time_unix_nano(_meta), do: nil

  defp format_body({:string, chardata}), do: IO.chardata_to_string(chardata)
  defp format_body({:report, report}), do: inspect(report)

  defp format_body({format, args}) when is_list(args) or is_binary(format),
    do: format |> :io_lib.format(List.wrap(args)) |> IO.chardata_to_string()

  defp format_body(other), do: inspect(other)

  defp build_attributes(meta) do
    meta
    |> Map.drop(@internal_meta)
    |> Scrubber.scrub_params()
    |> Map.merge(source_attributes(meta))
  end

  defp source_attributes(meta) do
    %{}
    |> put_present("code.filepath", format_chardata(Map.get(meta, :file)))
    |> put_present("code.lineno", Map.get(meta, :line))
    |> put_present("code.function", format_mfa(Map.get(meta, :mfa)))
  end

  defp put_present(map, _key, nil), do: map
  defp put_present(map, key, value), do: Map.put(map, key, value)

  defp format_chardata(nil), do: nil
  defp format_chardata(value) when is_binary(value), do: value
  defp format_chardata(value), do: IO.chardata_to_string(value)

  defp format_mfa({mod, fun, arity}), do: "#{inspect(mod)}.#{fun}/#{arity}"
  defp format_mfa(_), do: nil
end
