import Config

config :eiseron_core, Eiseron.I18n.Locale,
  gettext_backend: EiseronCore.Test.Gettext,
  default_locale: "pt_BR"

config :eiseron_core, :network_resolver, Eiseron.Network.ResolverMock

config :argon2_elixir, t_cost: 1, m_cost: 8
