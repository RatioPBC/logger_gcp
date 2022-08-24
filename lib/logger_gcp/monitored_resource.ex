defmodule LoggerGCP.MonitoredResource do
  @moduledoc """
  generic_node MonitoredResource utilities.
  """

  alias GoogleApi.Logging.V2.Model.MonitoredResource

  @monitored_resource_type "generic_node"

  def start_link do
    Agent.start_link(
      fn ->
        %MonitoredResource{
          type: @monitored_resource_type,
          labels: init()
        }
      end,
      name: __MODULE__
    )
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end

  defp init do
    Enum.reduce(init_order(), %{}, fn fun, config ->
      try do
        Map.merge(fun.(), config)
      rescue
        ArgumentError -> config
      end
    end)
  end

  defp init_order, do: [&init_defaults/0, &init_from_config/0, &init_from_environment/0]

  defp init_defaults do
    %{
      project_id: default_project_id(),
      location: default_location(),
      namespace: default_namespace(),
      node_id: default_node_id()
    }
  end

  defp default_project_id, do: "project-logger-gcp"
  defp default_location, do: "us-west-2"
  defp default_namespace, do: "logger-gcp"

  defp default_node_id do
    {:ok, hostname} = :inet.gethostname()

    to_string(hostname)
  end

  defp init_from_config do
    Application.fetch_env!(:logger_gcp, :monitored_resource)
  end

  defp init_from_environment do
    %{
      project_id: System.fetch_env!("LOGGER_GCP_PROJECT_ID"),
      location: System.fetch_env!("LOGGER_GCP_LOCATION"),
      namespace: System.fetch_env!("LOGGER_GCP_NAMESPACE"),
      node_id: System.fetch_env!("LOGGER_GCP_NAMESPACE")
    }
  end
end
