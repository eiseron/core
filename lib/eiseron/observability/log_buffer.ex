defmodule Eiseron.Observability.LogBuffer do

  use GenServer

  alias Eiseron.Observability.OTLP

  @flush_interval 2_000
  @max_batch 200

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def record(server \\ __MODULE__, record), do: GenServer.cast(server, {:record, record})

  @impl true
  def init(opts) do
    state = %{
      endpoint: Keyword.fetch!(opts, :endpoint),
      resource: Keyword.fetch!(opts, :resource),
      flush_interval: Keyword.get(opts, :flush_interval, @flush_interval),
      max_batch: Keyword.get(opts, :max_batch, @max_batch),
      poster:
        Keyword.get(opts, :poster, default_poster(Keyword.get(opts, :finch, __MODULE__.Finch))),
      buffer: []
    }

    schedule_flush(state.flush_interval)
    {:ok, state}
  end

  @impl true
  def handle_cast({:record, record}, state) do
    buffer = [record | state.buffer]
    {:noreply, flush_when(%{state | buffer: buffer}, length(buffer) >= state.max_batch)}
  end

  @impl true
  def handle_info(:flush, state) do
    schedule_flush(state.flush_interval)
    {:noreply, flush(state)}
  end

  defp flush_when(state, false), do: state
  defp flush_when(state, true), do: flush(state)

  defp flush(%{buffer: []} = state), do: state

  defp flush(state) do
    payload = OTLP.build_logs_payload(Enum.reverse(state.buffer), state.resource)
    state.poster.(state.endpoint, payload)
    %{state | buffer: []}
  end

  defp schedule_flush(interval), do: Process.send_after(self(), :flush, interval)

  defp default_poster(finch) do
    fn endpoint, payload ->
      request = Finch.build(:post, endpoint <> "/v1/logs", json_headers(), Jason.encode!(payload))
      Finch.request(request, finch)
    end
  end

  defp json_headers, do: [{"content-type", "application/json"}]
end
