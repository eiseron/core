defmodule Eiseron.Identity.Password do
  @min_length 12
  @strength_rules [:too_short, :missing_lowercase, :missing_uppercase, :missing_digit]

  def min_length, do: @min_length

  def hash(plaintext, pepper) when is_binary(plaintext) and is_binary(pepper) do
    Argon2.hash_pwd_salt(plaintext <> pepper)
  end

  def verify(plaintext, hashed, pepper)
      when is_binary(plaintext) and is_binary(hashed) and is_binary(pepper) do
    Argon2.verify_pass(plaintext <> pepper, hashed)
  end

  def verify(_plaintext, _hashed, _pepper) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Returns `:ok` or `{:error, reason}` where reason is one of:
  `:too_short | :missing_lowercase | :missing_uppercase | :missing_digit | :not_a_string`.
  Callers are responsible for translating the atom to a user-facing message.
  """
  def validate_strength(password) when is_binary(password) do
    Enum.reduce_while(@strength_rules, :ok, fn rule, _acc ->
      if obeys?(rule, password), do: {:cont, :ok}, else: {:halt, {:error, rule}}
    end)
  end

  def validate_strength(_), do: {:error, :not_a_string}

  defp obeys?(:too_short, password), do: String.length(password) >= @min_length
  defp obeys?(:missing_lowercase, password), do: String.match?(password, ~r/[a-z]/)
  defp obeys?(:missing_uppercase, password), do: String.match?(password, ~r/[A-Z]/)
  defp obeys?(:missing_digit, password), do: String.match?(password, ~r/[0-9]/)
end
