defmodule Eiseron.ErrorMonitoring.FinchClient do
  @moduledoc "Sentry HTTP client backed by Finch, shared across Eiseron products."

  @behaviour Sentry.HTTPClient

  @finch Eiseron.ErrorMonitoring.Finch

  @impl true
  def child_spec do
    Finch.child_spec(name: @finch)
  end

  @impl true
  def post(url, headers, body) do
    case Finch.request(Finch.build(:post, url, headers, body), @finch) do
      {:ok, %Finch.Response{status: status, headers: resp_headers, body: resp_body}} ->
        {:ok, status, resp_headers, resp_body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
