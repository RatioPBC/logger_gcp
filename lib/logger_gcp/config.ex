defmodule LoggerGCP.Config do
  @moduledoc """
  Config to be kept close in state, used during LoggerGCP.loop/1.
  """

  alias GoogleApi.Logging.V2.Api.Entries
  alias GoogleApi.Logging.V2.Model.MonitoredResource

  @monitored_resource_type "generic_node"

  defstruct [
    :credentials,
    :dry_run,
    :entries,
    :log_name,
    :monitored_resource,
    :write_timer_disabled
  ]

  def init do
    %__MODULE__{
      credentials: init_credentials(),
      dry_run: Application.get_env(:logger_gcp, :dry_run, false),
      entries: Application.get_env(:logger_gcp, :entries, Entries),
      log_name: init_log_name(),
      monitored_resource: init_monitored_resource(),
      write_timer_disabled: Application.get_env(:logger_gcp, :write_timer, [])[:disabled]
    }
  end

  defp init_credentials do
    client_id = from_env("GOOGLE_CLIENT_ID", [:credentials, :client_id], :require_provided)

    client_secret =
      from_env("GOOGLE_CLIENT_SECRET", [:credentials, :client_secret], :require_provided)

    refresh_token =
      from_env("GOOGLE_REFRESH_TOKEN", [:credentials, :refresh_token], :require_provided)

    %{
      "client_id" => client_id,
      "client_secret" => client_secret,
      "refresh_token" => refresh_token
    }
  end

  defp init_log_name do
    logs_id = from_env("LOGGER_GCP_LOG_ID", :log_id, :required_provided)
    project = from_env("LOGGER_GCP_PROJECT_ID", :project_id, :required_provided)

    "projects/#{project}/logs/#{logs_id}"
  end

  defp init_monitored_resource do
    %MonitoredResource{
      type: @monitored_resource_type,
      labels: init_labels()
    }
  end

  defp init_labels do
    %{
      location: from_env("LOGGER_GCP_LOCATION", :location, ""),
      namespace: from_env("LOGGER_GCP_NAMESPACE", :namespace, ""),
      node_id: from_env("LOGGER_GCP_NODE_ID", :node_id, default_node_id()),
      project_id: from_env("LOGGER_GCP_PROJECT_ID", :project_id, :require_provided)
    }
  end

  defp default_node_id do
    {:ok, hostname} = :inet.gethostname()

    to_string(hostname)
  end

  # ---

  def from_env(env_key, config_key, default \\ nil) do
    case fetch_value(env_key, config_key, default) do
      :require_provided ->
        msg =
          "config value missing: either set #{env_key} in your environment, or\n" <>
            "\tconfig :logger_gcp, #{inspect(config_key)}, <value>"

        IO.warn(msg)
        raise(msg)

      value ->
        value
    end
  end

  defp fetch_value(env_key, config_key, default) do
    case System.get_env(env_key) do
      nil ->
        try do
          fetch_config_value(config_key, default)
        catch
          :require_provided ->
            :require_provided
        end

      value ->
        value
    end
  end

  defp fetch_config_value(config_key, default) when is_atom(config_key) do
    Application.get_env(:logger_gcp, config_key, default)
  end

  defp fetch_config_value(config_key, default) when is_list(config_key) do
    [key | path] = config_key

    :logger_gcp
    |> Application.get_env(key, default)
    |> get_in_value(path)
  end

  defp get_in_value(:require_provided, _path), do: throw(:require_provided)

  defp get_in_value(enum, path), do: get_in(enum, path)
end
