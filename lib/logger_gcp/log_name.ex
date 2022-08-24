defmodule LoggerGCP.LogName do
  @moduledoc """
  Log name agent.
  """

  def init do
    Agent.start_link(
      fn ->
        project = Application.fetch_env!(:logger_gcp, :project)
        logs_id = Application.fetch_env!(:logger_gcp, :id)

        "projects/#{project}/logs/#{logs_id}"
      end,
      name: __MODULE__
    )
  end

  def get do
    Agent.get(__MODULE__, & &1)
  end
end
