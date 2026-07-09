defmodule Eiseron.ErrorMonitoring.Scrubber do
  @sensitive ~w(password passwd secret token authorization api_key cookie session email cpf phone telefone)

  @email ~r/[\w.!#$%&'*+\/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)+/
  @cpf ~r/\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/
  @phone ~r/\b(?:\+?55[\s-]?)?\(?\d{2}\)?[\s-]?9?\d{4}[-\s]?\d{4}\b/

  def scrub_record(%{body: body, attributes: attributes} = record) do
    %{record | body: scrub_text(body), attributes: scrub_params(attributes)}
  end

  def scrub_record(record), do: record

  def scrub_params(params) when is_map(params) do
    Map.new(params, fn {key, value} -> {key, scrub_pair(key, value)} end)
  end

  def scrub_params(list) when is_list(list), do: Enum.map(list, &scrub_params/1)

  def scrub_params(value) when is_binary(value), do: scrub_text(value)

  def scrub_params(value), do: value

  def scrub_text(value) when is_binary(value) do
    value
    |> String.replace(@email, "[REDACTED_EMAIL]")
    |> String.replace(@cpf, "[REDACTED_CPF]")
    |> String.replace(@phone, "[REDACTED_PHONE]")
  end

  def scrub_text(value), do: value

  defp scrub_pair(key, value) do
    if sensitive?(key), do: "[Filtered]", else: scrub_params(value)
  end

  defp sensitive?(key) do
    normalized = key |> to_string() |> String.downcase()
    Enum.any?(@sensitive, &String.contains?(normalized, &1))
  end
end
