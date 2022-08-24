defmodule LoggerGCPTest do
  use ExUnit.Case, async: false

  import LoggerGCP.Test.Helpers

  alias GoogleApi.Logging.V2.Model.LogEntry
  alias GoogleApi.Logging.V2.Model.MonitoredResource
  alias GoogleApi.Logging.V2.Model.WriteLogEntriesRequest

  require Logger

  describe "init/0" do
    test "registers process" do
      refute is_nil(Process.whereis(LoggerGCP))
    end

    test "adds LoggerJSON backend" do
      assert :ok = Logger.configure_backend(LoggerJSON, [])
    end

    test "initializes MonitoredResource Agent" do
      mr = LoggerGCP.MonitoredResource.get()

      assert %MonitoredResource{
               labels: labels,
               type: type
             } = mr

      assert is_map(labels)

      for k <- [:location, :namespace, :node_id, :project_id] do
        assert Map.has_key?(labels, k)
        assert is_binary(labels[k])
        assert String.length(labels[k]) > 0
      end

      assert type == "generic_node"
    end

    test "initializes ETS table" do
      send_logger_gcp({:fetch_state, self()})

      receive do
        {:state, state} ->
          assert info = :ets.info(state.table)
          assert Keyword.fetch!(info, :type) == :bag
          assert Keyword.fetch!(info, :owner) == Process.whereis(LoggerGCP)
      end
    end

    test "initializes connection" do
      send_logger_gcp({:fetch_state, self()})

      receive do
        {:state, state} ->
          assert state.connection == "connection mock"
      end
    end
  end

  describe "ETS table" do
    setup [:clear_ets_table]

    test "logs are inserted for proper level" do
      Logger.error("test")
      Logger.flush()

      # assert [json] = fetch_entries()
      # assert map = Jason.decode!(json)
      assert [map] = fetch_entries()

      assert map["message"] == "test"
      assert map["severity"] == "error"
      assert {:ok, %DateTime{}, 0} = DateTime.from_iso8601(map["time"])
      assert is_map(map["metadata"])
    end

    test "logs are NOT inserted for lesser level" do
      Logger.debug("test")
      Logger.flush()
      assert fetch_entries() == []
    end
  end

  describe "using Google API" do
    setup [:clear_ets_table, :clear_entries_mock]

    test "log entry is sent via WriteLogEntriesRequest struct" do
      Logger.error("test")
      Logger.flush()
      assert [ets_json] = fetch_entries()

      LoggerGCP
      |> Process.whereis()
      |> send(:write_timeout)

      assert fetch_entries() == []

      assert [
               {"connection mock",
                %WriteLogEntriesRequest{
                  dryRun: true,
                  entries: [entry],
                  resource: resource
                }}
             ] = LoggerGCP.Test.EntriesMock.fetch_args()

      # TODO: see if possible to have LoggerJSON deliver map instead of string
      #
      # note that LogEntry is expecting a map, so we have to *decode*; one
      # can only assume this will *re-encode* again later. this does not seem
      # optimal.
      #
      # *   `jsonPayload` (*type:* `map()`, *default:* `nil`)
      #
      # See: https://github.com/googleapis/elixir-google-api/blob/main/clients/logging/lib/google_api/logging/v2/model/log_entry.ex
      #
      assert %LogEntry{jsonPayload: le_json, logName: log_name} = entry
      assert ets_json == le_json

      # see config/test.exs
      assert log_name == "projects/test-project/logs/test-id"

      assert LoggerGCP.MonitoredResource.get() == resource
    end
  end
end
