import Config

config :logger, backends: [LoggerJSON]

config :logger_json,
  backend: [
    device: LoggerGCP,
    json_encoder: Jason
  ]

# elixir-google-api uses Tesla underneath for clients.
# set Tesla to use Hackney to avoid:
#
#     Description: 'Authenticity is not established by certificate path validation'
#         Reason: 'Option {verify, verify_peer} and cacertfile/cacerts is missing'
#
config :tesla, adapter: Tesla.Adapter.Hackney

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
env_config = "#{Mix.env()}.exs"
if File.exists?("config/" <> env_config), do: import_config(env_config)
