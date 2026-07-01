defmodule Eiseron.ErrorMonitoring.ScrubberTest do
  use ExUnit.Case, async: true

  alias Eiseron.ErrorMonitoring.Scrubber

  @sensitive ~w(password passwd secret token authorization api_key cookie session email cpf phone telefone)

  for key <- @sensitive do
    test "redacts the #{key} key" do
      assert Scrubber.scrub_params(%{unquote(key) => "x"})[unquote(key)] == "[Filtered]"
    end
  end

  test "keeps a benign key untouched" do
    assert Scrubber.scrub_params(%{"venturi_mm" => "34"})["venturi_mm"] == "34"
  end

  test "redacts a sensitive key nested in a map" do
    scrubbed = Scrubber.scrub_params(%{"setup" => %{"secret" => "s"}})

    assert scrubbed["setup"]["secret"] == "[Filtered]"
  end

  test "redacts a sensitive key nested in a list" do
    scrubbed = Scrubber.scrub_params(%{"items" => [%{"api_key" => "k"}]})

    assert hd(scrubbed["items"])["api_key"] == "[Filtered]"
  end
end
