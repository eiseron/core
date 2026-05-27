defmodule Eiseron.I18n.Resolver do
  alias Eiseron.I18n.Locale

  def resolve(%{} = inputs) do
    valid_or_nil(inputs[:url_param]) ||
      valid_or_nil(inputs[:user_preferred]) ||
      valid_or_nil(inputs[:workspace_default]) ||
      Locale.parse_accept_language(inputs[:accept_language]) ||
      Map.fetch!(inputs, :fallback)
  end

  defp valid_or_nil(value) do
    if Locale.valid?(value), do: value, else: nil
  end
end
