defmodule Eiseron.Identity.EmailNormalizer do
  def normalize(value) when is_binary(value) do
    value |> String.trim() |> String.downcase()
  end

  def normalize(value), do: value
end
