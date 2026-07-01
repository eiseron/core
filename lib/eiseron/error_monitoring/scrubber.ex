defmodule Eiseron.ErrorMonitoring.Scrubber do
  @moduledoc "Pure PII scrubbing for request params attached to error-monitor events."

  @sensitive ~w(password passwd secret token authorization api_key cookie session email cpf phone telefone)

  def scrub_params(params) when is_map(params) do
    Map.new(params, fn {key, value} -> {key, scrub_pair(key, value)} end)
  end

  def scrub_params(list) when is_list(list), do: Enum.map(list, &scrub_params/1)

  def scrub_params(value), do: value

  defp scrub_pair(key, value) do
    if sensitive?(key), do: "[Filtered]", else: scrub_params(value)
  end

  defp sensitive?(key) do
    normalized = key |> to_string() |> String.downcase()
    Enum.any?(@sensitive, &String.contains?(normalized, &1))
  end
end
