import Config

config :logger, level: :info

config :logger_gcp,
  auth: LoggerGCP.AuthMock,
  connection: LoggerGCP.ConnectionMock,
  credentials: [
    client_id: "<id>",
    client_secret: "<secret>",
    refresh_token: "<token>"
  ],
  ets: [extra_options: [:public]],
  write_timer: [disabled: true]
