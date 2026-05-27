defmodule Eiseron.Identity.EmailNormalizerTest do
  use ExUnit.Case, async: true

  alias Eiseron.Identity.EmailNormalizer

  describe "normalize/1" do
    test "lowercases mixed-case input" do
      assert EmailNormalizer.normalize("Foo@Bar.COM") == "foo@bar.com"
    end

    test "trims surrounding whitespace" do
      assert EmailNormalizer.normalize("  user@example.test\n") == "user@example.test"
    end

    test "preserves '+' aliases" do
      assert EmailNormalizer.normalize("alice+work@example.test") == "alice+work@example.test"
    end

    test "is idempotent" do
      input = "  Mixed@Case.IO  "

      assert EmailNormalizer.normalize(input) ==
               input |> EmailNormalizer.normalize() |> EmailNormalizer.normalize()
    end

    test "passes non-binary values through unchanged" do
      assert EmailNormalizer.normalize(nil) == nil
    end
  end
end
