defmodule LoggerGCP.Test.Helpers do
  @moduledoc false

  def send_logger_gcp(message) do
    case Process.whereis(LoggerGCP) do
      nil ->
        raise "no process registered: LoggerGCP"

      pid ->
        send(pid, message)
    end
  end

  # ---

  def clear_ets_table(_ \\ nil) do
    true =
      fetch_ets_table!()
      |> :ets.delete(:logger_gcp)

    :ok
  end

  def fetch_ets_table! do
    send_logger_gcp({:fetch_state, self()})

    receive do
      {:state, state} -> Map.fetch!(state, :table)
    end
  end

  def fetch_entries do
    send_logger_gcp({:fetch_entries, self()})

    receive do
      {:entries, entries} -> entries
    end
  end

  # ---

  def clear_entries_mock(_ \\ nil), do: LoggerGCP.Test.EntriesMock.clear()
end
