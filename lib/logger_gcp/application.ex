defmodule LoggerGCP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Supervisor.start_link([LoggerGCP], strategy: :one_for_one)
  end
end
