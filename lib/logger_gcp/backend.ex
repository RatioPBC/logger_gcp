defmodule LoggerGCP.Backend do
  @moduledoc """
  Logger backend for Google Cloud Logging.
  """

  alias LoggerJSON.Formatters.GoogleCloudLogger

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event(
        {level, _group_leader, {Logger, message, timestamp, metadata}},
        %{level: min_level} = state
      ) do
    IO.inspect(metadata, label: "metadata")

    if Logger.compare_levels(level, min_level) != :lt do
      GoogleCloudLogger.format_event(level, message, timestamp, metadata, [])
      |> Jason.encode!()
      |> IO.puts()
    end

    {:ok, state}
  end

  def init({__MODULE__, name}) do
    {:ok, configure(name, [])}
  end

  # --- configure

  # emtpy opts indicates initial configure
  defp configure(name, []) do
    base_level = Application.get_env(:logger, :level, :debug)

    Application.get_env(:logger, name, [])
    |> Enum.into(%{
      name: name,
      level: base_level
    })
  end

  # handle runtime config
  defp configure(_name, [level: new_level], state), do: %{state | level: new_level}

  # noop everything else
  defp configure(_name, _opts, state), do: state
end
