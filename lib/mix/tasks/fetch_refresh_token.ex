defmodule Mix.Tasks.FetchRefreshToken do
  @moduledoc """
  Runs user through an OAuth flow to obtain a non-expiring refresh token with
  Google Cloud Logging write scope.

  Usage:

      $ mix fetch_refresh_token https://example.com/redirect/uri

  """

  @shortdoc "Fetch refresh token for Google Cloud Logging"

  use Mix.Task

  require Logger

  @scope "https://www.googleapis.com/auth/logging.write"
  @token_url 'https://oauth2.googleapis.com/token'
  @content_type 'application/x-www-form-urlencoded'

  @impl true
  def run([]) do
    IO.warn("redirect_uri argument required")
  end

  @impl true
  def run([redirect_uri]) do
    config = LoggerGCP.Config.init()
    auth_url = authorize_url(config, redirect_uri)

    IO.puts("Please visit and authorize:\n\t" <> auth_url)
    IO.puts("\nEnter code (or full URL with code query param):")

    code = IO.read(:line) |> String.trim() |> parse_code()

    refresh_token =
      config
      |> token_post_body(redirect_uri, code)
      |> fetch_tokens()
      |> Jason.decode!()
      |> Map.fetch!("refresh_token")

    IO.puts("\nrefresh_token:\n\t" <> refresh_token)
  end

  defp authorize_url(config, redirect_uri) do
    %URI{
      scheme: "https",
      host: "accounts.google.com",
      path: "/o/oauth2/auth",
      query:
        URI.encode_query(%{
          "access_type" => "offline",
          "client_id" => config.credentials["client_id"],
          "prompt" => "consent",
          "redirect_uri" => redirect_uri,
          "response_type" => "code",
          "scope" => @scope
        })
    }
    |> URI.to_string()
  end

  defp token_post_body(config, redirect_uri, code) do
    URI.encode_query(
      %{
        "client_id" => config.credentials["client_id"],
        "client_secret" => config.credentials["client_secret"],
        "code" => code,
        "grant_type" => "authorization_code",
        "redirect_uri" => redirect_uri,
        "scope" => nil
      },
      :www_form
    )
  end

  defp parse_code(code) do
    case URI.parse(code) do
      %URI{query: query} ->
        query
        |> URI.decode_query()
        |> Map.fetch!("code")

      %URI{scheme: nil, host: nil, query: nil, path: code} ->
        code
    end
  end

  defp fetch_tokens(request_body) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    cacertfile = CAStore.file_path() |> String.to_charlist()

    if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      Logger.debug("Using HTTPS_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
    end

    http_options = [
      ssl: [
        verify: :verify_peer,
        cacertfile: cacertfile,
        depth: 2,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    case :httpc.request(:post, {@token_url, [], @content_type, request_body}, http_options, []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise "couldn't fetch #{@token_url}: #{inspect(other)}"
    end
  end
end
