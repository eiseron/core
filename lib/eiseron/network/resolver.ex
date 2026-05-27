defmodule Eiseron.Network.Resolver do
  @callback getaddrs(host :: charlist(), family :: :inet | :inet6) ::
              {:ok, [:inet.ip_address()]} | {:error, term()}

  defmodule Erlang do
    @moduledoc false
    @behaviour Eiseron.Network.Resolver

    @impl true
    def getaddrs(host, family), do: :inet.getaddrs(host, family)
  end
end
