defmodule Neptuner.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Only load dotenv and Mix tasks in development/test
    # Mix and dotenv are not available in production releases
    if Code.ensure_loaded?(Mix) and Code.ensure_loaded?(Dotenv) and Mix.env() != :prod do
      Dotenv.load()
      Mix.Task.run("loadconfig")
    end

    children = [
      NeptunerWeb.Telemetry,
      Neptuner.Repo,
      {DNSCluster, query: Application.get_env(:neptuner, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:neptuner, Oban)},
      {Phoenix.PubSub, name: Neptuner.PubSub},
      {NeptunerWeb.RateLimit, clean_period: :timer.minutes(1)},
      # Start a worker by calling: Neptuner.Worker.start_link(arg)
      # {Neptuner.Worker, arg},
      # Start to serve requests, typically the last entry
      NeptunerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Neptuner.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NeptunerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
