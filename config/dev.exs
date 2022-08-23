import Config

if File.exists?(Path.join("config", "dev.secret.exs")) do
  import_config("dev.secret.exs")
else
  raise "'dev.secret.exs' not found. please create and add:\n" <>
          """
              import Config

              config :logger_gcp,
                credentials: [
                  client_id: "<id>",
                  client_secret: "<secret>",
                  refresh_token: "<token>"
                ]
          """
end
