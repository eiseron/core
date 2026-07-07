defmodule Eiseron.Observability do
  alias Eiseron.Observability.{Error, LogBuffer, LoggerHandler, Traces}

  @handler_id :eiseron_observability
  @default_buffer Eiseron.Observability.LogBuffer

  def setup(opts) do
    attach_when(opts, export?(opts))
  end

  def report(kind, reason, stacktrace, meta \\ %{}) do
    kind |> Error.build_record(reason, stacktrace, meta) |> LogBuffer.record()
    :ok
  end

  def detach do
    :logger.remove_handler(@handler_id)
    :ok
  end

  defp attach_when(_opts, false), do: :ok

  defp attach_when(opts, true) do
    handler = %{level: :info, config: %{buffer: Keyword.get(opts, :buffer, @default_buffer)}}
    normalize_add(:logger.add_handler(@handler_id, LoggerHandler, handler))
    Traces.setup(opts)
  end

  defp normalize_add(:ok), do: :ok
  defp normalize_add({:error, {:already_exist, _}}), do: :ok

  def endpoint(opts), do: normalize_endpoint(Keyword.get(opts, :otlp_endpoint))

  def config(opts) do
    endpoint = opts |> Keyword.get(:otlp_endpoint) |> normalize_endpoint()

    [
      opentelemetry: [
        span_processor: :batch,
        traces_exporter: traces_exporter(endpoint),
        resource: resource(opts)
      ],
      opentelemetry_exporter: [
        otlp_protocol: :http_protobuf,
        otlp_endpoint: endpoint
      ]
    ]
  end

  def resource(opts) do
    %{
      "service.name" => to_string(Keyword.fetch!(opts, :service)),
      "deployment.environment" => to_string(Keyword.get(opts, :env, "dev")),
      "service.version" => to_string(Keyword.get(opts, :version, "0.0.0"))
    }
  end

  def export?(opts),
    do: traces_exporter(normalize_endpoint(Keyword.get(opts, :otlp_endpoint))) == :otlp

  defp normalize_endpoint(nil), do: nil
  defp normalize_endpoint(""), do: nil
  defp normalize_endpoint(endpoint) when is_binary(endpoint), do: String.trim(endpoint)

  defp traces_exporter(nil), do: :none
  defp traces_exporter(_endpoint), do: :otlp
end
