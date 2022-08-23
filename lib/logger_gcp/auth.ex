defmodule LoggerGCP.Auth do
  @moduledoc """
  Handle authentication with GCP. Currently, implemented with `Goth`.

  See: https://github.com/peburrows/goth
  """

  def start_goth() do
    Goth.start_link(name: LoggerGCP.Goth, source: {:refresh_token, credentials(), []})
  end

  defp credentials do
    :logger_gcp
    |> Application.fetch_env!(:credentials)
    |> Keyword.take([:client_id, :client_secret, :refresh_token])
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Map.new()
  end

  def fetch_token(_scopes) do
    LoggerGCP.Goth
    |> Goth.fetch!()
    |> Map.fetch!(:token)
  end
end
