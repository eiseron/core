defmodule Eiseron.Observability.Traces do

  alias Eiseron.Observability

  def setup(opts) do
    setup_when(opts, Observability.export?(opts))
  end

  defp setup_when(_opts, false), do: :ok

  defp setup_when(opts, true) do
    setup_phoenix(Keyword.get(opts, :phoenix))
    setup_ecto(Keyword.get(opts, :ecto))
    :ok
  end

  defp setup_phoenix(nil), do: :ok
  defp setup_phoenix(false), do: :ok
  defp setup_phoenix(true), do: OpentelemetryPhoenix.setup(adapter: :bandit)

  defp setup_phoenix(phoenix_opts) when is_list(phoenix_opts) do
    OpentelemetryPhoenix.setup(Keyword.put_new(phoenix_opts, :adapter, :bandit))
  end

  defp setup_ecto(nil), do: :ok
  defp setup_ecto([]), do: :ok
  defp setup_ecto(prefixes), do: Enum.each(prefixes, &OpentelemetryEcto.setup/1)
end
