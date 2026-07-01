import Config

config :sentry, client: Eiseron.ErrorMonitoring.FinchClient, dsn: nil, send_default_pii: false

import_config "#{config_env()}.exs"
