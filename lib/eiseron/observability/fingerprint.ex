defmodule Eiseron.Observability.Fingerprint do
  def build(kind, reason, stacktrace) do
    (exception_type(kind, reason) <> "|" <> top_frame(stacktrace))
    |> hash()
  end

  def exception_type(:error, %{__struct__: module}), do: inspect(module)
  def exception_type(:error, reason), do: normalize_reason(reason)
  def exception_type(kind, _reason), do: to_string(kind)

  defp normalize_reason(reason) when is_atom(reason), do: to_string(reason)

  defp normalize_reason(reason) when is_tuple(reason) and tuple_size(reason) > 0,
    do: normalize_reason(elem(reason, 0))

  defp normalize_reason(reason), do: inspect(reason)

  defp top_frame([frame | _]), do: frame_signature(frame)
  defp top_frame(_), do: "unknown"

  defp frame_signature({module, function, arity, location}) do
    "#{inspect(module)}.#{function}/#{frame_arity(arity)} #{frame_location(location)}"
  end

  defp frame_signature(other), do: inspect(other)

  defp frame_arity(arity) when is_integer(arity), do: arity
  defp frame_arity(args) when is_list(args), do: length(args)

  defp frame_location(location) do
    file = location |> Keyword.get(:file, ~c"") |> to_string()
    "#{file}:#{Keyword.get(location, :line, 0)}"
  end

  defp hash(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower) |> binary_part(0, 16)
  end
end
