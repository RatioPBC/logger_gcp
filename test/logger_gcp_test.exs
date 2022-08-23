defmodule LoggerGCPTest do
  use ExUnit.Case, async: false

  import LoggerGCP.Test.Helpers

  require Logger

  describe "ETS table" do
    setup [:clear_ets_table]

    test "logs are inserted for proper level" do
      Logger.error("test")
      Logger.flush()
      assert [json] = fetch_entries()
      assert map = Jason.decode!(json)
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

  describe "writing to GCP" do
  end
end
