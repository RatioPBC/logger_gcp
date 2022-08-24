defmodule LoggerGCP.ConfigTest do
  use ExUnit.Case, async: false

  alias GoogleApi.Logging.V2.Model.MonitoredResource

  alias LoggerGCP.Config

  describe "init/0" do
    test "initializes struct" do
      assert Config.init() == %Config{
               dry_run: true,
               entries: LoggerGCP.Test.EntriesMock,
               log_name: "projects/test-project/logs/test-id",
               monitored_resource: %MonitoredResource{
                 labels: %{
                   location: "Earth",
                   namespace: "LoggerGCP.Test",
                   node_id: "test-node",
                   project_id: "test-project"
                 },
                 type: "generic_node"
               },
               write_timer_disabled: true
             }
    end
  end

  describe "from_env/3" do
    test "loads env var" do
      env_key = init_env_key(1, true)
      assert Config.from_env(env_key, :undefined) == "env_value_1"
    end

    test "loads config value without env var" do
      env_key = init_env_key(2)
      config_key = init_config_key(2, true)
      assert Config.from_env(env_key, config_key) == "config_value_2"
    end

    test "prefers env var to config value" do
      env_key = init_env_key(3, true)
      config_key = init_config_key(3, true)
      assert Config.from_env(env_key, config_key) == "env_value_3"
    end

    test "requires provided value" do
      env_key = init_env_key(4)
      config_key = init_config_key(4)

      assert_raise RuntimeError, fn ->
        Config.from_env(env_key, config_key, :require_provided)
      end
    end

    test "requires provided value with env var" do
      env_key = init_env_key(5, true)
      config_key = init_config_key(5)
      assert Config.from_env(env_key, config_key, :require_provided) == "env_value_5"
    end

    test "requires provided value with config value" do
      env_key = init_env_key(6)
      config_key = init_config_key(6, true)
      assert Config.from_env(env_key, config_key, :require_provided) == "config_value_6"
    end

    test "fallsback to default string" do
      env_key = init_env_key(7)
      config_key = init_config_key(7)
      assert Config.from_env(env_key, config_key, "default_value_7") == "default_value_7"
    end

    test "fallsback to default non-string" do
      env_key = init_env_key(8)
      config_key = init_config_key(8)
      assert Config.from_env(env_key, config_key, :default_value_8) == :default_value_8
      assert Config.from_env(env_key, config_key, DefaultValue8) == DefaultValue8
    end
  end

  def init_env_key(num, value \\ false) do
    env_key = "LOGGER_GCP_TEST_ENV_VAR_#{num}"
    assert System.fetch_env(env_key) == :error

    if value, do: System.put_env(env_key, "env_value_#{num}")

    env_key
  end

  def init_config_key(num, value \\ false) do
    config_key = :"test_config_key_#{num}"
    assert Application.fetch_env(:logger_gcp, config_key) == :error

    if value, do: Application.put_env(:logger_gcp, config_key, "config_value_#{num}")

    config_key
  end
end
