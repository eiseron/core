defmodule Eiseron.Network.GuardDestinationTest do
  use ExUnit.Case, async: false

  import Mox

  alias Eiseron.Network.Guard
  alias Eiseron.Network.ResolverMock

  setup :verify_on_exit!

  setup do
    on_exit(fn -> Application.put_env(:eiseron_core, :network, []) end)
    :ok
  end

  describe "validate_destination/1 — happy path" do
    test "returns the resolved IP when DNS yields a single public address" do
      expect(ResolverMock, :getaddrs, fn ~c"public.example.com", :inet ->
        {:ok, [{1, 2, 3, 4}]}
      end)

      assert Guard.validate_destination("https://public.example.com/hook") == {:ok, "1.2.3.4"}
    end

    test "returns the first resolved IP when DNS yields multiple public addresses" do
      expect(ResolverMock, :getaddrs, fn _, :inet -> {:ok, [{1, 2, 3, 4}, {5, 6, 7, 8}]} end)

      assert {:ok, "1.2.3.4"} = Guard.validate_destination("https://public.example.com/hook")
    end
  end

  describe "validate_destination/1 — DNS-rebinding rejections" do
    test "rejects when DNS resolves to a private IPv4" do
      expect(ResolverMock, :getaddrs, fn _, :inet -> {:ok, [{10, 0, 0, 1}]} end)

      assert Guard.validate_destination("https://rebind.example.com/hook") ==
               {:error, :private_host}
    end

    test "rejects when DNS resolves to loopback" do
      expect(ResolverMock, :getaddrs, fn _, :inet -> {:ok, [{127, 0, 0, 1}]} end)

      assert Guard.validate_destination("https://localhost-rebind.example.com/hook") ==
               {:error, :private_host}
    end

    test "rejects when DNS yields a mix of public and private addresses" do
      expect(ResolverMock, :getaddrs, fn _, :inet -> {:ok, [{1, 2, 3, 4}, {10, 0, 0, 1}]} end)

      assert Guard.validate_destination("https://mixed.example.com/hook") ==
               {:error, :private_host}
    end
  end

  describe "validate_destination/1 — DNS failures" do
    test "returns :unresolved when DNS lookup fails with :nxdomain" do
      expect(ResolverMock, :getaddrs, fn _, :inet -> {:error, :nxdomain} end)

      assert Guard.validate_destination("https://nope.example.invalid/hook") ==
               {:error, :unresolved}
    end

    test "returns :unresolved on :timeout" do
      expect(ResolverMock, :getaddrs, fn _, :inet -> {:error, :timeout} end)

      assert Guard.validate_destination("https://slow.example.com/hook") ==
               {:error, :unresolved}
    end
  end
end
