import Config

config :logger_gcp,
  log_id: "example-id",
  location: "example-location",
  namespace: "example-namespace",
  project_id: "example-project"

if File.exists?(Path.join("config", "dev.secret.exs")) do
  import_config("dev.secret.exs")
end
