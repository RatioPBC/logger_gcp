import Config

config :logger, backends: [LoggerJSON]

config :logger_json,
  backend: [
    device: LoggerGCP,
    json_encoder: {Jason, :encode!}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
env_config = "#{config_env()}.exs"
if File.exists?("config/" <> env_config), do: import_config(env_config)