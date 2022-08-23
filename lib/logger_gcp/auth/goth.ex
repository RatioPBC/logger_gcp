defmodule LoggerGCP.Auth.Goth do
  @behaviour LoggerGCP.Auth
  @moduledoc """
  Handle authentication with GCP with `Goth`. Expects a credentials keyword
  list to be configured at `:logger_gcp, :credentials`.

  See: https://github.com/peburrows/goth
  """

  @impl true
  def init() do
    Goth.start_link(name: LoggerGCP.Goth, source: {:refresh_token, credentials(), []})
  end

  defp credentials do
    :logger_gcp
    |> Application.fetch_env!(:credentials)
    |> Keyword.take([:client_id, :client_secret, :refresh_token])
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Map.new()
  end

  @impl true
  def fetch_token(_scopes) do
    LoggerGCP.Goth
    |> Goth.fetch!()
    |> Map.fetch!(:token)
  end
end
