import Config

config :logger, level: :info

config :logger_gcp,
  credentials: [
    client_id: "<id>",
    client_secret: "<secret>",
    refresh_token: "<token>"
  ],
  ets: [extra_options: [:public]]
