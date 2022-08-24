defmodule LoggerGCP.Test.AuthMock do
  @behaviour LoggerGCP.Auth

  @impl true
  def init, do: :ok

  @impl true
  def fetch_token(_scopes), do: "Bearer token"
end

# ---

defmodule LoggerGCP.Test.Behaviours.Connection do
  @callback new(function()) :: term()
end

defmodule LoggerGCP.Test.ConnectionMock do
  @behaviour LoggerGCP.Test.Behaviours.Connection

  @impl true
  def new(_fun), do: "connection mock"
end

# ---
defmodule LoggerGCP.Test.Behaviours.Entries do
  @callback logging_entries_write(term(),
              body: GoogleApi.Logging.V2.Model.WriteLogEntriesRequest.t()
            ) :: term()
end

defmodule LoggerGCP.Test.EntriesMock do
  @behaviour LoggerGCP.Test.Behaviours.Entries

  @impl true
  def logging_entries_write(conn, body: wler) do
    maybe_init()
    |> Agent.update(fn args -> [{conn, wler} | args] end)
  end

  def fetch_args do
    maybe_init()
    |> Agent.get(& &1)
  end

  def clear do
    maybe_init()
    |> Agent.update(fn _ -> [] end)
  end

  defp maybe_init do
    if pid = Process.whereis(__MODULE__) do
      pid
    else
      {:ok, pid} = Agent.start_link(fn -> [] end, name: __MODULE__)
      pid
    end
  end
end
