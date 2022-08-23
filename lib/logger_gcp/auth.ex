defmodule LoggerGCP.Auth do
  @moduledoc """
  Authentication with Google API behaviour.
  """

  alias LoggerGCP.Auth.Goth

  @callback init() :: :ok
  @callback fetch_token([String.t()]) :: String.t()

  def init(), do: impl().init()

  def fetch_token(scopes), do: impl().fetch_token(scopes)

  defp impl, do: Application.get_env(:logger_gcp, :auth, Goth)
end
