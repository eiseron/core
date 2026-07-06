defmodule Eiseron.Observability.Supervisor do

  use Supervisor

  alias Eiseron.Observability
  alias Eiseron.Observability.LogBuffer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Supervisor.init(children(opts, Observability.export?(opts)), strategy: :one_for_one)
  end

  defp children(_opts, false), do: []

  defp children(opts, true) do
    finch = Keyword.get(opts, :finch, LogBuffer.Finch)

    [
      {Finch, name: finch},
      {LogBuffer,
       [
         endpoint: Observability.endpoint(opts),
         resource: Observability.resource(opts),
         finch: finch
       ]}
    ]
  end
end
