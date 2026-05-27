defmodule Eiseron.Network.GuardTest do
  use ExUnit.Case, async: false

  alias Eiseron.Network.Guard

  describe "restricted_url?/1 — string-level rejections" do
    test "rejects URL with embedded space" do
      assert Guard.restricted_url?("http://example.com /hook") == {:error, :control_chars}
    end

    test "rejects URL with tab" do
      assert Guard.restricted_url?("http://example.com\t/hook") == {:error, :control_chars}
    end

    test "rejects URL with CR" do
      assert Guard.restricted_url?("http://example.com\r/hook") == {:error, :control_chars}
    end

    test "rejects URL with LF" do
      assert Guard.restricted_url?("http://example.com\n/hook") == {:error, :control_chars}
    end

    test "rejects URL with userinfo (basic auth)" do
      assert Guard.restricted_url?("http://user:pass@example.com/hook") ==
               {:error, :credentials}
    end

    test "rejects URL with userinfo (no password)" do
      assert Guard.restricted_url?("http://attacker@example.com/hook") ==
               {:error, :credentials}
    end

    test "rejects URL with non-http(s) scheme" do
      assert Guard.restricted_url?("ftp://example.com/hook") == {:error, :invalid_scheme}
    end

    test "rejects URL with no host" do
      assert Guard.restricted_url?("http:///hook") == {:error, :invalid_scheme}
    end

    test "rejects non-string input" do
      assert Guard.restricted_url?(nil) == {:error, :invalid_scheme}
    end
  end

  describe "restricted_url?/1 — host-level rejections" do
    test "rejects http://localhost" do
      assert Guard.restricted_url?("http://localhost/hook") == {:error, :private_host}
    end

    test "rejects http://127.0.0.1" do
      assert Guard.restricted_url?("http://127.0.0.1/hook") == {:error, :private_host}
    end

    test "rejects http://10.0.0.1 (RFC1918)" do
      assert Guard.restricted_url?("http://10.0.0.1/hook") == {:error, :private_host}
    end

    test "rejects http://192.168.1.1 (RFC1918)" do
      assert Guard.restricted_url?("http://192.168.1.1/hook") == {:error, :private_host}
    end

    test "rejects http://172.16.0.1 (RFC1918 lower bound)" do
      assert Guard.restricted_url?("http://172.16.0.1/hook") == {:error, :private_host}
    end

    test "rejects http://172.31.255.255 (RFC1918 upper bound)" do
      assert Guard.restricted_url?("http://172.31.255.255/hook") == {:error, :private_host}
    end

    test "rejects http://169.254.169.254 (cloud metadata)" do
      assert Guard.restricted_url?("http://169.254.169.254/latest/meta-data") ==
               {:error, :private_host}
    end

    test "rejects http://0.0.0.0" do
      assert Guard.restricted_url?("http://0.0.0.0/hook") == {:error, :private_host}
    end
  end

  describe "restricted_url?/1 — valid public URLs" do
    test "accepts a public HTTPS URL" do
      assert Guard.restricted_url?("https://example.com/hook") == :ok
    end

    test "accepts a public HTTP URL" do
      assert Guard.restricted_url?("http://example.com/hook") == :ok
    end
  end

  describe "private_network_address?/1 — IPv4" do
    test "loopback 127.0.0.1" do
      assert Guard.private_network_address?({127, 0, 0, 1})
    end

    test "RFC1918 10.x.x.x" do
      assert Guard.private_network_address?({10, 0, 0, 1})
    end

    test "RFC1918 172.16-31.x.x" do
      assert Guard.private_network_address?({172, 16, 0, 1})
      assert Guard.private_network_address?({172, 31, 255, 255})
      refute Guard.private_network_address?({172, 15, 0, 1})
      refute Guard.private_network_address?({172, 32, 0, 1})
    end

    test "RFC1918 192.168.x.x" do
      assert Guard.private_network_address?({192, 168, 1, 1})
    end

    test "link-local 169.254.x.x" do
      assert Guard.private_network_address?({169, 254, 169, 254})
    end

    test "public 1.1.1.1 is not private" do
      refute Guard.private_network_address?({1, 1, 1, 1})
    end
  end

  describe "private_network_address?/1 — IPv6" do
    test "loopback ::1" do
      assert Guard.private_network_address?({0, 0, 0, 0, 0, 0, 0, 1})
    end

    test "ULA fc00::1" do
      assert Guard.private_network_address?({0xFC00, 0, 0, 0, 0, 0, 0, 1})
    end

    test "link-local fe80::1" do
      assert Guard.private_network_address?({0xFE80, 0, 0, 0, 0, 0, 0, 1})
    end

    test "IPv4-mapped ::ffff:127.0.0.1 (recurses into IPv4 loopback)" do
      assert Guard.private_network_address?({0, 0, 0, 0, 0, 0xFFFF, 0x7F00, 0x0001})
    end

    test "IPv4-mapped ::ffff:8.8.8.8 is not private" do
      refute Guard.private_network_address?({0, 0, 0, 0, 0, 0xFFFF, 0x0808, 0x0808})
    end
  end

  describe "encoded_ip?/1" do
    test "hex-encoded 0x7f000001" do
      assert Guard.encoded_ip?("0x7f000001")
    end

    test "decimal integer 2130706433" do
      assert Guard.encoded_ip?("2130706433")
    end

    test "two-part short form 127.0" do
      assert Guard.encoded_ip?("127.0")
    end

    test "rejects normal four-part 127.0.0.1" do
      refute Guard.encoded_ip?("127.0.0.1")
    end

    test "rejects domain example.com" do
      refute Guard.encoded_ip?("example.com")
    end
  end

  describe "trusted hosts allowlist" do
    setup do
      previous = Application.get_env(:eiseron_core, :network, [])

      Application.put_env(
        :eiseron_core,
        :network,
        Keyword.put(previous, :trusted_hosts, ["localhost", "127.0.0.1"])
      )

      on_exit(fn -> Application.put_env(:eiseron_core, :network, previous) end)
    end

    test "restricted_host? returns false for allowlisted localhost" do
      refute Guard.restricted_host?("localhost")
    end

    test "restricted_host? still blocks non-allowlisted private host" do
      assert Guard.restricted_host?("192.168.1.1")
    end

    test "restricted_ip? returns false for allowlisted IP" do
      refute Guard.restricted_ip?("127.0.0.1")
    end

    test "restricted_ip? still blocks non-allowlisted private IP" do
      assert Guard.restricted_ip?("10.0.0.1")
    end
  end
end
