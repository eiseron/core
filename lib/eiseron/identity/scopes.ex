defmodule Eiseron.Identity.Scopes do
  @scopes ~w(
    read:workspaces
    read:monitors
    write:monitors
    read:logs
    read:metrics
    read:incidents
    read:channels
    write:channels
    ping:channels
    read:delivery_logs
  )

  def all, do: @scopes

  def valid?(scope) when is_binary(scope), do: scope in @scopes
  def valid?(_), do: false

  def all_valid?(scopes) when is_list(scopes), do: Enum.all?(scopes, &valid?/1)
  def all_valid?(_), do: false
end
