defmodule LoggerGCP do
  @moduledoc """
  `LoggerGCP` is an IO server for use with `LoggerJSON` and `GoogleApi.Logging`.
  This is most useful for applications running external to GCP, but wanting to
  send logs directly there.

  See: https://www.erlang.org/doc/apps/stdlib/io_protocol.html
  """

  defstruct [:connection, :table, :timer]

  alias GoogleApi.Logging.V2.Connection
  alias GoogleApi.Logging.V2.Api.Entries
  alias GoogleApi.Logging.V2.Model.LogEntry
  alias GoogleApi.Logging.V2.Model.WriteLogEntriesRequest

  alias LoggerGCP.Auth
  alias LoggerGCP.LogName
  alias LoggerGCP.MonitoredResource

  @max_entries_per_write_request 100
  @milliseconds_between_writes 5_000

  @select_match_spec [{{:logger_gcp, :"$1"}, [], [:"$1"]}]
  @select_count_match_spec [{{:logger_gcp, :_}, [], [true]}]

  def child_spec(_),
    do: %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }

  def start_link, do: Task.start_link(__MODULE__, :init, [])

  def init do
    Process.register(self(), __MODULE__)
    init_logger_json()
    Auth.init()
    LogName.init()
    MonitoredResource.init()

    table = create_ets_table()
    conn = connection_impl().new(&Auth.fetch_token/1)

    %__MODULE__{connection: conn, table: table}
    |> queue_next_write()
    |> loop()
  end

  defp init_logger_json do
    lj_backend_set =
      Application.fetch_env!(:logger, :backends)
      |> Enum.any?(&(&1 == LoggerJSON))

    if lj_backend_set, do: Logger.add_backend(LoggerJSON)
  end

  defp create_ets_table do
    extra_opts =
      :logger_gcp
      |> Application.get_env(:ets, [])
      |> Keyword.get(:extra_options, [])

    :ets.new(:noname, [:bag] ++ extra_opts)
  end

  defp connection_impl, do: Application.get_env(:logger_gcp, :connection, Connection)

  # --- loop

  defp loop(%__MODULE__{table: table} = state) do
    receive do
      {:io_request, from, reply_as, {:put_chars, :unicode, entry}} ->
        entry = Jason.decode!(entry)
        :ets.insert(table, {:logger_gcp, entry})
        send(from, {:io_reply, reply_as, :ok})

        state
        |> maybe_write()
        |> loop()

      {:fetch_entries, from} ->
        entries = :ets.select(table, @select_match_spec)
        send(from, {:entries, entries})
        loop(state)

      {:fetch_state, from} ->
        send(from, {:state, state})
        loop(state)

      :write_timeout ->
        if count_entries(table) > 0 do
          state
          |> write()
          |> loop()
        else
          state
          |> queue_next_write()
          |> loop()
        end

      _ ->
        loop(state)
    end
  end

  defp maybe_write(%__MODULE__{table: table} = state) do
    if count_entries(table) >= @max_entries_per_write_request,
      do: write(state),
      else: state
  end

  defp count_entries(table),
    do: :ets.select_count(table, @select_count_match_spec)

  defp write(%__MODULE__{connection: conn, table: table} = state) do
    write_request =
      table
      |> :ets.select(@select_match_spec)
      |> build_write_request()

    case entries_impl().logging_entries_write(conn, body: write_request) do
      {:ok, _} ->
        :ets.delete_all_objects(table)

      {:error, %Tesla.Env{body: body}} ->
        IO.warn("Google Logging API call fail:\n#{body}")
    end

    queue_next_write(state)

    state
  end

  defp build_write_request(entries) do
    entries = for e <- entries, do: %LogEntry{jsonPayload: e, logName: LogName.get()}

    %WriteLogEntriesRequest{
      dryRun: Application.get_env(:logger_gcp, :dry_run, true),
      entries: entries,
      resource: MonitoredResource.get()
    }
  end

  defp entries_impl, do: Application.get_env(:logger_gcp, :entries, Entries)

  # ---

  defp cancel_timer(%__MODULE__{timer: nil} = state), do: state

  defp cancel_timer(%__MODULE__{timer: timer} = state) do
    Process.cancel_timer(timer)
    %__MODULE__{state | timer: nil}
  end

  defp queue_next_write(state) do
    if Application.get_env(:logger_gcp, :write_timer, [])[:disabled] do
      state
    else
      timer = Process.send_after(self(), :write_timeout, @milliseconds_between_writes)

      state
      |> cancel_timer()
      |> Map.put(:timer, timer)
    end
  end
end
