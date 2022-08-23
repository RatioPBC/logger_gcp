defmodule LoggerGCP.AuthMock do
  @behaviour LoggerGCP.Auth

  @impl true
  def init, do: :ok

  @impl true
  def fetch_token(_scopes), do: "Bearer token"
end

defmodule LoggerGCP.Test.Connection do
  @callback new(function()) :: term()
end

defmodule LoggerGCP.ConnectionMock do
  @behaviour LoggerGCP.Test.Connection

  @impl true
  def new(_fun), do: "connection mock"
end
