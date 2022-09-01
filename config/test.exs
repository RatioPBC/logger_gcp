import Config

config :logger, level: :info

# normal config required
config :logger_gcp,
  credentials: "config/test_credentials.json",
  location: "Earth",
  log_id: "test-id",
  namespace: "LoggerGCP.Test",
  node_id: "test-node",
  project_id: "test-project"

# config specific to testing
config :logger_gcp,
  auth: LoggerGCP.Test.AuthMock,
  connection: LoggerGCP.Test.ConnectionMock,
  dry_run: true,
  entries: LoggerGCP.Test.EntriesMock,
  ets: [extra_options: [:public]],
  write_timer: [disabled: true]
