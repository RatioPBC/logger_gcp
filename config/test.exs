import Config

config :logger, level: :info

config :logger_gcp,
  auth: LoggerGCP.Test.AuthMock,
  connection: LoggerGCP.Test.ConnectionMock,
  credentials: [
    client_id: "<id>",
    client_secret: "<secret>",
    refresh_token: "<token>"
  ],
  dry_run: true,
  entries: LoggerGCP.Test.EntriesMock,
  ets: [extra_options: [:public]],
  write_timer: [disabled: true]
