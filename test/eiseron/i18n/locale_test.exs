defmodule Eiseron.I18n.LocaleTest do
  use ExUnit.Case, async: true

  alias Eiseron.I18n.Locale

  describe "supported/0" do
    test "returns the locales discovered by the configured Gettext backend" do
      assert Locale.supported() == ~w(en pt_BR)
    end
  end

  describe "default/0" do
    test "returns the configured default locale" do
      assert Locale.default() == "pt_BR"
    end
  end

  describe "valid?/1" do
    test "accepts every supported locale" do
      for locale <- Locale.supported() do
        assert Locale.valid?(locale), "expected #{inspect(locale)} to be valid"
      end
    end

    test "rejects locales outside supported/0" do
      refute Locale.valid?("de")
      refute Locale.valid?("pt")
      refute Locale.valid?("PT_BR")
      refute Locale.valid?("en-GB")
    end

    test "rejects non-binary input" do
      refute Locale.valid?(nil)
      refute Locale.valid?(:pt_BR)
      refute Locale.valid?(123)
    end
  end

  describe "parse_accept_language/1" do
    test "returns en for the literal en tag" do
      assert Locale.parse_accept_language("en") == "en"
    end

    test "returns pt_BR for the literal pt_BR tag" do
      assert Locale.parse_accept_language("pt_BR") == "pt_BR"
    end

    test "normalizes hyphenated BCP-47 form to Gettext underscore form" do
      assert Locale.parse_accept_language("pt-BR") == "pt_BR"
    end

    test "case-folds a lowercase region so pt-br resolves to pt_BR" do
      assert Locale.parse_accept_language("pt-br") == "pt_BR"
    end

    test "returns nil for bare language without a region" do
      assert Locale.parse_accept_language("pt") == nil
    end

    test "returns nil for an unsupported language code" do
      assert Locale.parse_accept_language("de") == nil
    end

    test "selects the highest-quality supported tag from a weighted list" do
      assert Locale.parse_accept_language("de;q=0.9, pt-BR;q=0.8, en;q=0.5") == "pt_BR"
    end

    test "treats missing q= as 1.0 and prefers the implicit-1.0 entry" do
      assert Locale.parse_accept_language("en, pt-BR;q=0.8") == "en"
    end

    test "returns nil for an empty header" do
      assert Locale.parse_accept_language("") == nil
    end

    test "returns nil when the input is nil" do
      assert Locale.parse_accept_language(nil) == nil
    end

    test "ignores extraneous whitespace around tags and parameters" do
      assert Locale.parse_accept_language("  pt-BR ; q=0.9 , en ; q=0.5  ") == "pt_BR"
    end

    test "treats malformed q values as the default 1.0 weight" do
      assert Locale.parse_accept_language("pt-BR;q=abc") == "pt_BR"
    end
  end
end
