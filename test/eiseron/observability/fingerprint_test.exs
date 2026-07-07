defmodule Eiseron.Observability.FingerprintTest do
  use ExUnit.Case, async: true

  alias Eiseron.Observability.Fingerprint

  @frame {MyApp.Worker, :run, 2, [file: ~c"lib/my_app/worker.ex", line: 42]}
  @stack [@frame, {MyApp.Other, :call, 1, [file: ~c"lib/my_app/other.ex", line: 7]}]

  test "groups the same exception type at the same top frame under one fingerprint" do
    a = Fingerprint.build(:error, %RuntimeError{message: "boom"}, @stack)
    b = Fingerprint.build(:error, %RuntimeError{message: "different message"}, @stack)
    assert a == b
  end

  test "separates different exception types at the same frame" do
    a = Fingerprint.build(:error, %RuntimeError{message: "x"}, @stack)
    b = Fingerprint.build(:error, %ArgumentError{message: "x"}, @stack)
    refute a == b
  end

  test "separates the same exception at a different top frame" do
    other = [{MyApp.Worker, :run, 2, [file: ~c"lib/my_app/worker.ex", line: 99]} | tl(@stack)]
    a = Fingerprint.build(:error, %RuntimeError{message: "x"}, @stack)
    b = Fingerprint.build(:error, %RuntimeError{message: "x"}, other)
    refute a == b
  end

  test "exception type of a struct error is its module" do
    assert Fingerprint.exception_type(:error, %Ecto.NoResultsError{message: "x"}) ==
             "Ecto.NoResultsError"
  end

  test "exception type of an erlang tuple error drops the variable payload" do
    assert Fingerprint.exception_type(:error, {:badmatch, %{secret: 1}}) == "badmatch"
  end

  test "exception type of a throw uses the kind" do
    assert Fingerprint.exception_type(:throw, :some_value) == "throw"
  end

  test "the fingerprint is a short lowercase hex digest" do
    fp = Fingerprint.build(:error, %RuntimeError{message: "x"}, @stack)
    assert fp =~ ~r/\A[0-9a-f]{16}\z/
  end
end
