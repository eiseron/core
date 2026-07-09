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

  test "redacts an email embedded in free text" do
    assert Scrubber.scrub_text("contato joao@example.com agora") =~ "[REDACTED_EMAIL]"
  end

  test "removes the raw email address from free text" do
    refute Scrubber.scrub_text("contato joao@example.com agora") =~ "joao@example.com"
  end

  test "redacts a formatted cpf in free text" do
    assert Scrubber.scrub_text("paciente 123.456.789-00") =~ "[REDACTED_CPF]"
  end

  test "redacts a bare 11-digit cpf in free text" do
    assert Scrubber.scrub_text("doc 12345678900 fim") =~ "[REDACTED_CPF]"
  end

  test "redacts a brazilian phone number in free text" do
    assert Scrubber.scrub_text("ligar (11) 98765-4321") =~ "[REDACTED_PHONE]"
  end

  test "keeps a short benign number untouched" do
    assert Scrubber.scrub_text("venturi 34 mm") == "venturi 34 mm"
  end

  test "redacts an email hidden in a benign attribute value" do
    scrubbed = Scrubber.scrub_params(%{"note" => "reply to ana@example.com"})

    assert scrubbed["note"] =~ "[REDACTED_EMAIL]"
  end

  test "scrubs the body of a record" do
    scrubbed = Scrubber.scrub_record(%{body: "user ana@example.com", attributes: %{}})

    assert scrubbed.body =~ "[REDACTED_EMAIL]"
  end

  test "scrubs the attributes of a record" do
    scrubbed = Scrubber.scrub_record(%{body: "ok", attributes: %{"token" => "abc"}})

    assert scrubbed.attributes["token"] == "[Filtered]"
  end
end
