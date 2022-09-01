# LoggerGCP

An IO device for use with [LoggerJSON](https://github.com/Nebo15/logger_json)
to write log entries to GCP Cloud Logging via
[elixir-google-api](https://github.com/googleapis/elixir-google-api).

Usually used for applications running somewhere else.

## Installation

First, add the dependency to your project.

```elixir
def deps do
  [
    {:logger_gcp, "~> 0.2"}
  ]
end
```

LoggerJSON 5.x will come with. Follow
[instructions](https://nebo15.github.io/logger_json/#installation) for setting
up LoggerJSON in the manner you desire, but note the following:

 * `LoggerGCP` *must* be set as LoggerJSON's backend device
 * LoggerGCP will [set](lib/logger_gcp.ex#L58-L64) LoggerJSON to use its
   GoogleCloudLogger formatter

The config should look something like this, for whichever environment you want
to log to Google:

```elixir
config :logger_json, :backend, device: LoggerGCP, metadata: :all
config :logger, backends: [LoggerJSON]
```

Then, configure LoggerGCP as follows.

## Configuration

### Environment Variables

| Variable | Description |
|---|---|
| `LOGGER_GCP_CREDENTIALS` | GCP Service Account JSON |
| `LOGGER_GCP_LOCATION` | Location value |
| `LOGGER_GCP_LOG_ID` | Log ID value |
| `LOGGER_GCP_NAMESPACE` | Namespace value |
| `LOGGER_GCP_NODE_ID` | Node ID value |
| `LOGGER_GCP_PROJECT_ID` | Project ID value |

### Config Keys

All keys should be set for `:logger_gcp` application.

| Variable | Description |
|---|---|
| `:credentials` | GCP Service Account JSON |
| `:location` | Location value |
| `:log_id` | Log ID value |
| `:namespace` | Namespace value |
| `:node_id` | Node ID value |
| `:project_id` | Project ID value |

### GCP Service Account JSON

This value may be:

 * a String path to a file with JSON contents (usually downloaded from GCP console)
 * the JSON content of the client\_secret file (in the case of environment
   variable) e.g.

```bash
export LOGGER_GCP_CREDENTIALS=$(cat secret.json)
```

 * a map as decoded from the JSON content of the client\_secret file (in the
   case of config value) e.g.

```elixir
config :logger_gcp, :credentials, %{
  "type" => "service_account",
  ...
}
```

### Examples

* See: [`config/test.exs`](config/test.exs)

```
export LOGGER_GCP_CREDENTIALS=/app/bin/example-project.client_secret.json
export LOGGER_GCP_LOCATION=Earth
export LOGGER_GCP_LOG_ID=example-id
export LOGGER_GCP_NAMESPACE=example-namespace
export LOGGER_GCP_NODE_ID=example-node-id
export LOGGER_GCP_PROJECT_ID=example-project-id
```
